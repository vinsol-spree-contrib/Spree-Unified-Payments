require 'spec_helper'

describe Spree::TransactionNotificationMailer do
  let(:card_transaction) { mock_model(UnifiedPayment::Transaction, :status => 'successful', :xml_response => '') }
  let(:order) { mock_model(Spree::Order) }
  let(:user) { mock_model(Spree::User) }

  before do
    @email = "test_user@westaycute.com"
    order.stub(:line_items).and_return([])
    card_transaction.stub(:order).and_return(order)
    card_transaction.stub(:user).and_return(user)
    user.stub(:email).and_return(@email)
  end
  describe 'fetches info from card_transaction' do
    it { card_transaction.should_receive(:order).and_return(order) }
    it { card_transaction.should_receive(:user).and_return(order) }
    it { user.should_receive(:email).and_return(@email) }
    it { card_transaction.should_receive(:status).and_return(card_transaction.status) }
    it { card_transaction.should_receive(:xml_response).and_return('') }

    after do
      Spree::TransactionNotificationMailer.send_mail(card_transaction)
    end
  end

  context 'when xml response is a message' do
    before do 
      card_transaction.stub(:xml_response).and_return("<Message><OrderStatus>Approved</OrderStatus></Message>")
    end

    it { Hash.should_receive(:from_xml).with(card_transaction.xml_response).and_return({'Message' => { 'OrderStatus' => 'Approved'} } ) }
    after do
      Spree::TransactionNotificationMailer.send_mail(card_transaction)
    end
  end

  context 'when xml response is not a message' do
    before do 
      card_transaction.stub(:xml_response).and_return("<NoMessage></NoMessage>")
    end

    it { Hash.should_not_receive(:from_xml) }
    after do
      Spree::TransactionNotificationMailer.send_mail(card_transaction)
    end
  end
end