module Spree
  #
  # UnifiedPaymentsController controls payment via UnifiedPayment
  # and has routes via methods : create, declined, canceled, approved
  #

  class UnifiedPaymentsController < StoreController
    # include UnifiedPayment::Utility
    include UnifiedTransactionHelper
    # 
    # before_filter :authenticate_spree_user!, :only => [:new, :create, :approved, :declined, :canceled]
    before_filter :ensure_valid_order, :only => [:new, :create]
    
    skip_before_filter :verify_authenticity_token, :only => [:approved, :declined, :canceled]

    before_filter :load_order_on_redirect, :only => [:declined, :canceled, :approved]
    before_filter :ensure_session_transaction_id, :only => :create

    def new
      session[:transaction_id] = generate_transaction_id
    end

    def create
      pending_card_transaction = @order.pending_card_transaction
      pending_card_transaction.try(:abort!)

      response = UnifiedPayment::Transaction.create_order_at_unified(naira_to_kobo(@order.total), { :approve_url => "#{root_url}unified_payments/approved", :cancel_url => "#{root_url}unified_payments/canceled", :decline_url => "#{root_url}unified_payments/declined", :description => "Purchasing items from #{Spree::Config[:site_name]}" })
      if response
        @payment_url = UnifiedPayment::Transaction.extract_url_for_unified_payment(response)
        tasks_after_order_create(response, session[:transaction_id])
      else
        @error_message = "Could not create payment at unified, please pay by other methods or try again later." 
      end
      render js: "$('#confirm_payment').hide();top.location.href = '#{@payment_url}'" if @payment_url
    end

    def declined
      transaction_unsuccesful_with_message("Payment declined")
    end

    def canceled
      transaction_unsuccesful_with_message("Successfully Canceled payment")
    end

    def approved
      @transaction_expired = @card_transaction.expired_at?
      @card_transaction.xml_response = params[:xmlmsg]
 
      @payment_made = @gateway_message_hash['PurchaseAmountScr'].to_f
      if @card_transaction.approved_at_gateway?
        if @card_transaction.amount != @payment_made
          add_error("Payment made was not same as requested to gateway. Please contact administrator for queries.")
          @card_transaction.status = 'unsuccessful'
        else
          @card_transaction.status = 'successful'

          if @transaction_expired
            add_error("Payment was successful but transaction has expired. The payment made has been walleted in your account. Please contact administrator to help you further.")
          elsif @order.paid? || @order.completed?
            add_error("Order Already Paid Or Completed")
          elsif @order.total != @payment_made
            add_error("Payment made is different from order total. Payment made has been walleted to your account.")
          end
        end
      else
        add_error("Not Approved At Gateway")
      end
      @card_transaction.save(:validate => false)
    end

    private
    
    def transaction_unsuccesful_with_message(message)
      @card_transaction.assign_attributes(:status => 'unsuccessful', :xml_response => params[:xmlmsg])
      @card_transaction.save(:validate => false)
      flash[:error] = message
    end

    def add_error(message)
      flash[:error] = flash[:error] ? [flash[:error], message].join('. ') : message
    end

    def order_invalid_with_message
      if !current_order 
        'No Order'
      else 
        current_order.reason_if_cant_pay_by_card
      end
    end

    def ensure_valid_order
      if @invalid_order_message = order_invalid_with_message
        flash[:error] = @invalid_order_message
        render js: "top.location.href='#{root_url}cart'"
      else 
        load_order
      end
    end

    def load_order
      @order = current_order
    end

    def load_order_on_redirect
      @gateway_message_hash = Hash.from_xml(params[:xmlmsg])['Message']
      if @card_transaction = UnifiedPayment::Transaction.where(:gateway_order_id => @gateway_message_hash['OrderID']).first
        @order = @card_transaction.order
      else
        flash[:error] = 'No transaction. Please contact our support team.'
        redirect_to '/'
      end
    end

    def tasks_after_order_create(response, transaction_id)
      response_order = response['Order']
      gateway_transaction = UnifiedPayment::Transaction.where(:gateway_session_id => response_order['SessionID'], :gateway_order_id => response_order['OrderID'], :url => response_order['URL']).first
      gateway_transaction.assign_attributes(:user_id => @order.user.try(:id), :payment_transaction_id => transaction_id, :order_id => @order.id, :gateway_order_status => 'CREATED', :amount => @order.total, :currency => Spree::Config[:currency], :response_status => response["Status"], :status => 'pending')
      gateway_transaction.save!

      @order.reserve_stock
      @order.next if @order.state == 'payment'
      session[:transaction_id] = nil
    end

    def ensure_session_transaction_id
      unless session[:transaction_id]
        flash[:error] = "No transaction id found, please try again"
        render js: "top.location.href = '#{root_url}checkout/payment'"
      end
    end
  end
end