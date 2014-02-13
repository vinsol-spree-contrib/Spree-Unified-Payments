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
        #No. We are not, hence using response
        @order = @card_transaction.order
        doc = Nokogiri::XML(@card_transaction.xml_response)
        @message = Hash.from_xml(doc.to_xml)['Message']
        render :layout => false
      end

      def query_gateway
        #[TODO_CR] Use @unified_payment_transaction.transaction_id Instead of defining another variable
        #[MK] Fixed.
        response = UnifiedPayment::Client.get_order_status(@card_transaction.gateway_order_id, @card_transaction.gateway_session_id)

        #[TODO_CR] Do we really need this variable?
        #[MK] made response a local variable instead.
        # @order_status = response["orderStatus"]

        #[TODO_CR] I thisnk this should be moved to model (UnifiedPayment::Transaction)
        # Also Aren't we doing same thing for user part too.
        #[MK] Moved.
        @card_transaction.update_transaction_on_query(response["orderStatus"])
      end

      private

      def load_transactions
        #[TODO_CR] I thing inplace of card_transaction we should use @unified_payment_transaction. This will reduce the consfusion.
        # What if transaction is not found?  We should handle this too.
        #[MK] All card transaction would be unified only since this is an extension. There should be no confusion.
        #[MK] Check added.
        @card_transaction = UnifiedPayment::Transaction.where(:payment_transaction_id => params[:transaction_id]).first
        render js: "alert('Could not find transaction')" unless @card_transaction
      end
    end
  end
end
