require 'spec_helper'

describe Spree::StoreCredit do
  describe 'attr-accessible' do
    [:balance, :user, :transactioner, :type].each do |attribute|
      it { should allow_mass_assignment_of attribute }
    end
  end

  it { should belong_to(:unified_transaction).class_name('UnifiedPayment::Transaction').with_foreign_key('unified_transaction_id') }
end