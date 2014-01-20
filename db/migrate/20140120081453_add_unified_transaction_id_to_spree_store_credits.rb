class AddUnifiedTransactionIdToSpreeStoreCredits < ActiveRecord::Migration
  def change
  	add_column :spree_store_credits, :unified_transaction_id, :integer
  	add_index :spree_store_credits, :unified_transaction_id
  end
end
