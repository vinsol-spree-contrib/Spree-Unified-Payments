class AddTransactionFieldsToUnifiedPaymentTransactions < ActiveRecord::Migration
  def change
    change_table :unified_payment_transactions do |t|
      t.references :order
      t.references :user
      t.string :payment_transaction_id
      t.datetime :expired_at
      t.string :status
      t.index :payment_transaction_id
      t.index :order_id
      t.index :user_id
    end
  end
end
