require 'spec_helper'

describe 'Constants' do
  it { UNIFIED_XML_CONTENT_MAPPING.should eq({ :masked_pan => 'PAN', :customer_name => 'Name', 
    :transaction_date_and_time => 'TranDateTime', :transaction_amount => 'PurchaseAmountScr', 
    :transaction_currency => 'CurrencyScr', :approval_code => 'ApprovalCode'}) }
  it { TRANSACTION_LIFETIME.should eq 5 }
  it { ADMIN_EMAIL.should eq "admin@#{Spree::Config[:site_name]}" }
  it { MERCHANT_NAME.should eq "#{Spree::Config[:site_name]}" }
  it { MERCHANT_URL.should eq "#{Spree::Config[:site_name]}" }
end