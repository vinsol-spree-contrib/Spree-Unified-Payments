Spree::User.class_eval do
  has_many :unified_payments, :class_name => 'UnifiedPayment::Transaction'
end