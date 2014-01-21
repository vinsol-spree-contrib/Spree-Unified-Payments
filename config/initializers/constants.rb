UNIFIED_XML_CONTENT_MAPPING = { :masked_pan => 'PAN', :customer_name => 'Name', 
  :transaction_date_and_time => 'TranDateTime', :transaction_amount => 'PurchaseAmountScr', 
  :transaction_currency => 'CurrencyScr', :approval_code => 'ApprovalCode'
}
TRANSACTION_LIFETIME = 5
ADMIN_EMAIL = "admin@#{Spree::Config[:site_name]}"
MERCHANT_NAME = "#{Spree::Config[:site_name]}"
MERCHANT_URL = "#{Spree::Config[:site_name]}"