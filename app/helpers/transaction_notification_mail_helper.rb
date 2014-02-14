module TransactionNotificationMailHelper
  def mail_content_hash_for_unified(info_hash, card_transaction)
    send_info = {}
    
    UNIFIED_XML_CONTENT_MAPPING.each_pair { |key, value| send_info[key] = info_hash[value] }
    
    send_info[:transaction_reference] = card_transaction.payment_transaction_id
    send_info[:merchants_name] = MERCHANT_NAME
    send_info[:merchants_url] = MERCHANT_URL
    send_info
  end
end