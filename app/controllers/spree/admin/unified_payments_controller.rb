module Spree
  module Admin
    class UnifiedPaymentsController < Spree::Admin::BaseController
      before_filter :load_transactions, :only => :query_gateway

      def index
        params[:q] ||= {}
        @search = UnifiedPayment::Transaction.order('updated_at desc').ransack(params[:q])
        @card_transactions = @search.result.page(params[:page]).per(20)
      end

      def receipt
        @card_transaction = UnifiedPayment::Transaction.where(:payment_transaction_id => params[:number]).first
        @order = @card_transaction.order
        doc = Nokogiri::XML(@card_transaction.xml_response)
        @message = Hash.from_xml(doc.to_xml)['Message']
        render :layout => false
      end

      def query_gateway
        @payment_transaction_id = params[:transaction_id]
        @response = UnifiedPayment::Client.get_order_status(@gateway_transaction.gateway_order_id, @gateway_transaction.gateway_session_id)
        @order_status = @response["orderStatus"]
        update_transaction_on_query(@card_transaction, @order_status)
      end

      private

      def load_transactions
        @card_transaction = UnifiedPayment::Transaction.where(:payment_transaction_id => params[:transaction_id]).first
        # @gateway_transaction = @card_transaction.gateway_transaction
      end

      def update_transaction_on_query(card_transaction, gateway_order_status)
        update_hash = gateway_order_status == "APPROVED" ? {:status => 'successful'} : {}
        @card_transaction.assign_attributes({:gateway_order_status => gateway_order_status}.merge(update_hash))
        @card_transaction.save(:validate => false)
      end
    end
  end
end
