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

  def stub_response(for_status)
  # options[:session_id] = options[:session_id] || 543

  transaction = current_order.unified_transactions.pending.last
  gateway_order_id = transaction.gateway_order_id

  "<Message date='23/01/2014 12:01:55'><Version>1.0</Version><OrderID>#{gateway_order_id}</OrderID><TransactionType>purchase</TransactionType><PAN>422584XXXX1097</PAN><PurchaseAmount>#{naira_to_kobo(current_order.outstanding_balance)}</PurchaseAmount><Currency>566</Currency><TranDateTime>23/01/2014 12:01:55</TranDateTime><ResponseCode>05</ResponseCode><ResponseDescription>Paid</ResponseDescription><Brand>VISA</Brand><OrderStatus>#{for_status}</OrderStatus><ApprovalCode></ApprovalCode><AcqFee>0</AcqFee><OrderDescription>Purchasing items from WeStayCute</OrderDescription><ApprovalCodeScr></ApprovalCodeScr><PurchaseAmountScr>#{current_order.outstanding_balance}</PurchaseAmountScr><CurrencyScr>Naira</CurrencyScr><OrderStatusScr>APPROVED</OrderStatusScr><Name>Dummy Test</Name><ThreeDSVerificaion>Y</ThreeDSVerificaion><ThreeDSStatus>Approved</ThreeDSStatus></Message>"
  end

  private

  def generate_id_using_timestamp(length = 14)
    (Time.current.to_i.to_s + [*(0..9)].sample(4).join.to_s)[0,length]
  end
end