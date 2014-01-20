module UnifiedTransactionHelper
  # def naira_to_kobo(amount)
  #   (amount.to_f)*100
  # end

  # def create_card_transaction(order, response, transaction_id)
  #   response_order = response['Order']
  #   gateway_transaction = UnifiedPayment::Transaction.where(:gateway_session_id => response_order['SessionID'], :gateway_order_id => response_order['OrderID'], :url => response_order['URL']).first
  #   gateway_transaction.build_card_transaction(:user_id => order.user.try(:id), :payment_transaction_id => transaction_id, :order_id => order.id, :gateway_order_status => 'CREATED', :amount => order.total, :currency => Spree::Config[:currency], :xml_response => response.inspect, :response_status => response["Status"], :status => 'pending')
  #   gateway_transaction.save!
  # end

  def generate_transaction_id
    (1..3).each do |attempt|
      @transaction_id = generate_id_using_timestamp + attempt.to_s
      break if UnifiedPayment::Transaction.where(:payment_transaction_id => @transaction_id).blank?
    end
    @transaction_id
  end

  private

  def generate_id_using_timestamp(length = 14)
    (Time.current.to_i.to_s + [*(0..9)].sample(4).join.to_s)[0,length]
  end
end