module Spree
  #
  # UnifiedPaymentsController controls payment via UnifiedPayment
  # and has routes via methods : create, declined, canceled, approved
  #

  class UnifiedPaymentsController < StoreController
    include UnifiedTransactionHelper

    before_filter :ensure_valid_order, :only => [:new, :create]    
    skip_before_filter :verify_authenticity_token, :only => [:approved, :declined, :canceled]

    before_filter :load_info_on_return, :only => [:declined, :canceled, :approved]
    before_filter :ensure_session_transaction_id, :abort_pending_transactions, :only => :create

    def index
      @card_transactions = spree_current_user.unified_payments.order('updated_at desc').page(params[:page]).per(20)
    end

    def new
      session[:transaction_id] = generate_transaction_id
    end

    def create
      # We also can extract these options is a method.
      #[MK] it was decided not giving any options since we want the requested to be redirected defined methods only
      response = UnifiedPayment::Transaction.create_order_at_unified(@order.total, { :approve_url => approved_unified_payments_url, :cancel_url => canceled_unified_payments_url, :decline_url => declined_unified_payments_url, :description => "Purchasing items from #{Spree::Config[:site_name]}" })
      if response
        @payment_url = UnifiedPayment::Transaction.extract_url_for_unified_payment(response)
        tasks_on_gateway_create_response(response, session[:transaction_id])
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
        if @card_transaction.amount.to_f != @payment_made
          process_unsuccessful_transaction
        else
          process_successful_transaction
        end
      else
        add_error("Not Approved At Gateway")
      end

      @card_transaction.save(:validate => false)
    end

    private
    
    def process_unsuccessful_transaction
      add_error("Payment made was not same as requested to gateway. Please contact administrator for queries.")
      @card_transaction.status = 'unsuccessful'
    end

    def process_successful_transaction
      @card_transaction.status = 'successful'

      if @transaction_expired
        add_error("Payment was successful but transaction has expired. The payment made has been walleted in your account. Please contact administrator to help you further.")
      elsif @order.paid? || @order.completed?
        add_error("Order Already Paid Or Completed")
      elsif @order.total != @payment_made
        add_error("Payment made is different from order total. Payment made has been walleted to your account.")
      end
    end

    def abort_pending_transactions
      pending_card_transaction = @order.pending_card_transaction
      pending_card_transaction.abort! if pending_card_transaction
    end

    def transaction_unsuccesful_with_message(message)
      @card_transaction.assign_attributes(:status => 'unsuccessful', :xml_response => params[:xmlmsg])
      @card_transaction.save(:validate => false)
      flash[:error] = message
    end

    def add_error(message)
      flash[:error] = flash[:error] ? [flash[:error], message].join('. ') : message
    end

    def order_invalid_with_message
      if current_order 
        current_order.reason_if_cant_pay_by_card
      else 
        'Order not found'
      end
    end

    def ensure_valid_order
      if @invalid_order_message = order_invalid_with_message
        flash[:error] = @invalid_order_message

        redirect_to cart_path
      else 
        load_order
      end
    end

    def load_order
      @order = current_order
    end

    def load_info_on_return
      @gateway_message_hash = Hash.from_xml(params[:xmlmsg])['Message']
      if @card_transaction = UnifiedPayment::Transaction.where(:gateway_order_id => @gateway_message_hash['OrderID']).first
        @order = @card_transaction.order
      else
        flash[:error] = 'No transaction. Please contact our support team.'        
        redirect_to root_path
      end
    end

    def tasks_on_gateway_create_response(response, transaction_id)
      response_order = response['Order']
      
      gateway_transaction = UnifiedPayment::Transaction.where(:gateway_session_id => response_order['SessionID'], :gateway_order_id => response_order['OrderID'], :url => response_order['URL']).first
      gateway_transaction.assign_attributes({:user_id => @order.user.try(:id), :payment_transaction_id => transaction_id, :order_id => @order.id, :gateway_order_status => 'CREATED', :amount => @order.total, :currency => Spree::Config[:currency], :response_status => response["Status"], :status => 'pending'}, :without_protection => true)
      gateway_transaction.save!

      @order.reserve_stock
      @order.next if @order.state == 'payment'
      session[:transaction_id] = nil
    end

    def ensure_session_transaction_id
      unless session[:transaction_id]
        flash[:error] = "No transaction id found, please try again"
        render js: "top.location.href = '#{checkout_state_url('payment')}'"
      end
    end
  end
end