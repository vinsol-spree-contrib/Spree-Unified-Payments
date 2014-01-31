module Spree
  module Admin
    class UnifiedPaymentsController < Spree::Admin::BaseController
      helper 'transaction_notification_mail'
      
      before_filter :load_transactions, :only => [:query_gateway, :receipt]

      def index
        params[:q] ||= {}
        @search = UnifiedPayment::Transaction.order('updated_at desc').ransack(params[:q])
        @card_transactions = @search.result.page(params[:page]).per(20)
      end

      def receipt
        #[TODO_CR] I thing we don't need to parse xml response. We are alredy storing almost all of the attributes in our db. 
        # Aren't we?
        @order = @card_transaction.order
        doc = Nokogiri::XML(@card_transaction.xml_response)
        @message = Hash.from_xml(doc.to_xml)['Message']
        render :layout => false
      end

      def query_gateway
        #[TODO_CR] Use @unified_payment_transaction.transaction_id Instead of defining another variable
        @payment_transaction_id = params[:transaction_id]
        @response = UnifiedPayment::Client.get_order_status(@card_transaction.gateway_order_id, @card_transaction.gateway_session_id)

        #[TODO_CR] Do we really need this variable?
        @order_status = @response["orderStatus"]

        #[TODO_CR] I thisnk this should be moved to model (UnifiedPayment::Transaction)
        # Also Aren't we doing same thing for user part too.
        update_transaction_on_query(@card_transaction, @order_status)
      end

      private

      def load_transactions
        #[TODO_CR] I thing inplace of card_transaction we should use @unified_payment_transaction. This will reduce the consfusion.
        # What if transaction is not found?  We should handle this too.
        @card_transaction = UnifiedPayment::Transaction.where(:payment_transaction_id => params[:transaction_id]).first
      end

      def update_transaction_on_query(card_transaction, gateway_order_status)
        update_hash = gateway_order_status == "APPROVED" ? {:status => 'successful'} : {}
        card_transaction.assign_attributes({:gateway_order_status => gateway_order_status}.merge(update_hash))
        #[TODO_CR] why saving without validations
        card_transaction.save(:validate => false)
      end
    end
  end
end
