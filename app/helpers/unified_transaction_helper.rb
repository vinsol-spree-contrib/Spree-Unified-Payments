module UnifiedTransactionHelper
  def naira_to_kobo(amount)
    (amount.to_f)*100
  end

  def generate_transaction_id
    begin
      payment_transaction_id = generate_id_using_timestamp
    end while UnifiedPayment::Transaction.exists?(payment_transaction_id: payment_transaction_id)
    payment_transaction_id
  end

  private

  def generate_id_using_timestamp(length = 14)
    (Time.current.to_i.to_s + [*(0..9)].sample(4).join.to_s)[0,length]
  end
end