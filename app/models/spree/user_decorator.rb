Spree::User.class_eval do
  has_many :unified_payments, :class_name => 'UnifiedPayment::Transaction'

  def self.create_unified_transaction_user(email)
    create(:email => email, :password => SecureRandom.hex(5))
  end
end