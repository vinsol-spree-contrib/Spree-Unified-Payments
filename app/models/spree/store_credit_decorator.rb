Spree::StoreCredit.class_eval do
  belongs_to :unified_transaction, :class_name => 'UnifiedPayment::Transaction', :foreign_key => 'unified_transaction_id'
end