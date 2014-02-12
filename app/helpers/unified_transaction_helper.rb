module UnifiedTransactionHelper
  def naira_to_kobo(amount)
    (amount.to_f)*100
  end

  # [TODO_CR] transaction generation seems a complicated what if we do somthing like below mentioned
  #
  # payment_transaction_id=''
  # begin
  #   payment_transaction_id = generate_id_using_timestamp
  # end while UnifiedPayment::Transaction.exists?(payment_transaction_id: payment_transaction_id)
  # payment_transaction_id
  #[MK] This method would allow infinite attempts. It was suggested to do 3 attempts at the first place.

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