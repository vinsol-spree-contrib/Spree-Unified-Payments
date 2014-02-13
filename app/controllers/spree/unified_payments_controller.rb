module Spree
  #
  # UnifiedPaymentsController controls payment via UnifiedPayment
  # and has routes via methods : create, declined, canceled, approved
  #

  class UnifiedPaymentsController < StoreController
    include UnifiedTransactionHelper

    before_filter :ensure_valid_order, :only => [:new, :create]    
    skip_before_filter :verify_authenticity_token, :only => [:approved, :declined, :canceled]

    before_filter :load_order_on_return, :only => [:declined, :canceled, :approved]
    before_filter :ensure_session_transaction_id, :abort_pending_transactions, :only => :create

    def index
      @card_transactions = spree_current_user.unified_payments.order('updated_at desc').page(params[:page]).per(20)
    end

    def new
      session[:transaction_id] = generate_transaction_id
    end

    def create
      #[TODO_CR] Extract this in a before filter and I am not sure why we are using try here, instead use if pending_card_transaction
      #[MK] Fixed.

      #[TODO_CR] Instead of root_url why we are not using approved_unified_payments_url
      # We also can extract these options is a method.
      #[MK] used route helpers, looks nicer.
      #[MK] it was decided not giving any options since we want the requested to be redirected defined methods only
      response = UnifiedPayment::Transaction.create_order_at_unified(@order.total, { :approve_url => approved_unified_payments_url, :cancel_url => canceled_unified_payments_url, :decline_url => declined_unified_payments_url, :description => "Purchasing items from #{Spree::Config[:site_name]}" })
      if response
        @payment_url = UnifiedPayment::Transaction.extract_url_for_unified_payment(response)
        tasks_on_gateway_create_response(response, session[:transaction_id])
      else
        @error_message = "Could not create payment at unified, please pay by other methods or try again later." 
      end

      #[TODO_CR] I guess this render belongs to if success condition.
      #[MK] if refering to if response condition, it seems better to have response at the end here.
      render js: "$('#confirm_payment').hide();top.location.href = '#{@payment_url}'" if @payment_url
    end

    def declined
      transaction_unsuccesful_with_message("Payment declined")
    end

    def canceled
      transaction_unsuccesful_with_message("Successfully Canceled payment")
    end

    #[TODO_CR] We should decompose this method?
    #[MK] Not able to break it down any further.
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
      #[TODO_CR] I think I am missing something here. Why we are saving without validations?
      #[MK] Because validations are needed for this save, the state was just updated, nothing else
      @card_transaction.save(:validate => false)
    end

    private
    
    def abort_pending_transactions
      pending_card_transaction = @order.pending_card_transaction
      pending_card_transaction.abort! if pending_card_transaction
    end

    def transaction_unsuccesful_with_message(message)
      @card_transaction.assign_attributes(:status => 'unsuccessful', :xml_response => params[:xmlmsg])

      #[TODO_CR] Same as above Line#75
      #[MK] Responded earlier.
      @card_transaction.save(:validate => false)
      flash[:error] = message
    end

    #[TODO_CR] There should be some better way of doing this.
    #[MK] like?
    def add_error(message)
      flash[:error] = flash[:error] ? [flash[:error], message].join('. ') : message
    end

    #[TODO_CR] Instead of using if !current_order we should use if current_order and switch code between if and else blocks
    #[MK] How does it make it better?
    def order_invalid_with_message
      if !current_order 
        #[TODO_CR] It should be "Order not found"
        #[MK] Changed.
        'Order not found'
      else 
        current_order.reason_if_cant_pay_by_card
      end
    end

    def ensure_valid_order
      if @invalid_order_message = order_invalid_with_message
        flash[:error] = @invalid_order_message

        #[TODO_CR] Any reason of not using cart_path
        #[MK] Changed.
        redirect_to cart_path
      else 
        load_order
      end
    end

    def load_order
      @order = current_order
    end

    #[TODO_CR] It should be load_transaction OR find_transaction
    #[MK] load_order_on_return seems better than load_order_on_redirect since it emphasises load on return from gateway making it more specific
    def load_order_on_return
      @gateway_message_hash = Hash.from_xml(params[:xmlmsg])['Message']
      if @card_transaction = UnifiedPayment::Transaction.where(:gateway_order_id => @gateway_message_hash['OrderID']).first
        @order = @card_transaction.order
      else
        flash[:error] = 'No transaction. Please contact our support team.'
        #[TODO_CR] Any reason of not using root_path
        #[MK] Changed.        
        redirect_to root_path
      end
    end

    #[TODO_CR] It seems the make of this method is not appropriate. It seems its doing things after spree_order create.
    # It should be somthing like. tasks_after_response_from_gateway. What you think?
    #[MK] Right. How about tasks_on_gateway_create_response? tasks_after_response can be for any or all responses
    def tasks_on_gateway_create_response(response, transaction_id)
      response_order = response['Order']

      #[TODO_CR] For most of the attributes mass assignment should not be allowed. Whay youy think?
      #[MK] We are updating though the xml response, its fine to have mass assignment here. Any particular reason?
      # Not sure why CREATED is hardcoded. It should be from response
      #[MK] Please refer to the response on order creation, there is no mention of any state in the response. State is fetched only when we ping for order status.
      
      # :status and currency assignment should be in model before validation/create
      #[MK] same as above for status, currency assignment seems to be fine here
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
        #[TODO_CR] No url hard coding 
        #[MK] Please suggest changes.
        render js: "top.location.href = '#{root_url}checkout/payment'"
      end
    end
  end
end