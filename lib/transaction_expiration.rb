class TransactionExpiration < Struct.new(:transaction_id)
  def perform
    card_transaction = UnifiedPayment::Transaction.where(:id => transaction_id).first
    if card_transaction.present? && card_transaction.status == 'pending'
      card_transaction.abort!
    end
  end
end