class TransactionExpiration < Struct.new(:transaction_id)
  def perform
    card_transaction = UnifiedPayment::Transaction.where(:id => transaction_id).first
    
    #[TODO_CR] no need to call present on card_transaction and use card_transaction.pending?
    # card_transaction && card_transaction.pending?
    #
    #[MK] Changes made.
    if card_transaction && card_transaction.pending?
      card_transaction.abort!
    end
  end
end