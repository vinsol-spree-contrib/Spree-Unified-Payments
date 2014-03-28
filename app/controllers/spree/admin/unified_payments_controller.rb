module Spree
  module Admin
    class UnifiedPaymentsController < Spree::Admin::BaseController
      helper 'transaction_notification_mail'
      
      before_filter :load_transactions, :only => [:query_gateway, :receipt]

      def model_class
        UnifiedPayment::Transaction
      end
      
      def index
        params[:q] ||= {}
        @search = UnifiedPayment::Transaction.order('updated_at desc').ransack(params[:q])
        @card_transactions = @search.result.page(params[:page]).per(20)
      end

      def receipt
        @order = @card_transaction.order
        @xml_response = @card_transaction.xml_response
        if @xml_response.include?('<Message')
          doc = Nokogiri::XML(@card_transaction.xml_response)
          @message = Hash.from_xml(doc.to_xml)['Message']
        end
        render :layout => false
      end

      def query_gateway
        response = UnifiedPayment::Client.get_order_status(@card_transaction.gateway_order_id, @card_transaction.gateway_session_id)
        @card_transaction.update_transaction_on_query(response["orderStatus"])
      end

      private

      def load_transactions
        @card_transaction = UnifiedPayment::Transaction.where(:payment_transaction_id => params[:transaction_id]).first
        render js: "alert('Could not find transaction')" unless @card_transaction
      end
    end
  end
end
