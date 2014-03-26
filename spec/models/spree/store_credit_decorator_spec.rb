require 'spec_helper'

describe Spree::StoreCredit do
  it { should belong_to(:unified_transaction).class_name('UnifiedPayment::Transaction').with_foreign_key('unified_transaction_id') }
end