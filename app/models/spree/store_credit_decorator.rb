Spree::StoreCredit.class_eval do
  attr_accessible :balance, :user, :transactioner, :type
  belongs_to :unified_transaction, :class_name => 'UnifiedPayment::Transaction', :foreign_key => 'unified_transaction_id'
end