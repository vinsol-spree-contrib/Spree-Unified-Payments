class AddUnifiedPaymentTransactions < ActiveRecord::Migration
  def change
    unless UnifiedPayment::Transaction.table_exists?
      create_table :unified_payment_transactions do |t|
        t.integer :gateway_order_id
        t.string :gateway_order_status
        t.string :amount
        t.string :gateway_session_id
        t.string :url
        t.string :merchant_id
        t.string :currency
        t.string :order_description
        t.string :response_status
        t.string :response_description
        t.string :pan
        t.string :approval_code
        t.text :xml_response
        t.timestamps
      end

      add_index :unified_payment_transactions, [:gateway_order_id, :gateway_session_id], name: :order_session_index
      add_index :unified_payment_transactions, :response_status
    end
  end
end