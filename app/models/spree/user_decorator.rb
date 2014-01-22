Spree::User.class_eval do
  has_many :unified_payments, :class_name => 'UnifiedPayment::Transaction'

  def self.create_unified_transaction_user(email, first_name, last_name, phone)
    create(:email => email, :password => SecureRandom.hex(5), :first_name => first_name, :last_name => last_name, :phone => phone)
  end
end