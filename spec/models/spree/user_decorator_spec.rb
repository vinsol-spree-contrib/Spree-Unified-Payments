require 'spec_helper'

describe Spree::User do
  it { should have_many(:unified_payments).class_name('UnifiedPayment::Transaction') }

  describe 'create_unified_transaction_user' do
    it 'creates a new user' do
      Spree::User.where(:email => 'new_user@unified.com').should be_blank
      Spree::User.create_unified_transaction_user('new_user@unified.com', 'new', 'user', '07123456789').should eq(Spree::User.where(:email => 'new_user@unified.com').first )
    end
  end
end