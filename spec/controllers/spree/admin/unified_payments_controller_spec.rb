require 'spec_helper'

describe Spree::Admin::UnifiedPaymentsController do
  let(:user) { mock_model(Spree::User) }
  let(:role) { mock_model(Spree::Role) }
  let(:card_transaction) { UnifiedPayment::Transaction.new( :gateway_order_id => '123213', :gateway_session_id => '1212', :payment_transaction_id => '123456', :xml_response => '<Message>123</Message>') }
  let(:order) { mock_model(Spree::Order) }
  let(:roles) { [role] }

  before do
    controller.stub(:spree_current_user).and_return(user)
    controller.stub(:authorize_admin).and_return(true)
    controller.stub(:authorize!).and_return(true)
    user.stub(:generate_spree_api_key!).and_return(true)
    user.stub(:roles).and_return(roles)
    roles.stub(:includes).and_return(roles)
    role.stub(:ability).and_return(true)
    card_transaction.stub(:order).and_return(order)
  end

  it { controller.model_class.should eq(UnifiedPayment::Transaction) }

  describe '#index' do
    def send_request(params = {})
      get :index, params.merge!(:use_route => 'spree', :page => 0)
    end

    before do
      UnifiedPayment::Transaction.stub(:order).with('updated_at desc').and_return(UnifiedPayment::Transaction)
      UnifiedPayment::Transaction.stub(:ransack).with({}).and_return(UnifiedPayment::Transaction)
      UnifiedPayment::Transaction.stub_chain(:result, :page, :per).with().with(0).with(20).and_return([card_transaction])
    end
    
    describe 'method calls' do
      it { UnifiedPayment::Transaction.should_receive(:order).with('updated_at desc').and_return(UnifiedPayment::Transaction) }
      it { UnifiedPayment::Transaction.should_receive(:ransack).with({}).and_return(UnifiedPayment::Transaction) }
      it { UnifiedPayment::Transaction.should_receive(:result) }
      it { UnifiedPayment::Transaction.result.page(0).per(20).should eq([card_transaction]) }
      
      after do
        send_request
      end
    end

    describe 'assigns' do
      it 'card_transactions' do
        send_request
        assigns(:card_transactions).should eq([card_transaction])
      end
    end
  end

  describe '#receipt' do
    def send_request(params = {})
      get :receipt, params.merge!(:use_route => 'spree')
    end

    context 'Transaction present' do
      before do
        UnifiedPayment::Transaction.stub(:where).with(:payment_transaction_id => '123456').and_return([card_transaction])
      end
      
      describe 'method calls' do
        it { UnifiedPayment::Transaction.should_receive(:where).with(:payment_transaction_id => '123456').and_return([card_transaction]) }
        it { card_transaction.should_receive(:order).and_return(order)}

        after do
          send_request(:transaction_id => '123456')
        end
      end

      it 'should render no layout' do
        send_request(:transaction_id => '123456')  
        response.should render_template(:layout => false)
      end

      describe 'assigns' do
        before do
          send_request(:transaction_id => '123456')
        end
        
        it { assigns(:message).should eq('123') }
      end
    end

    context 'No transaction present' do
      before do
        UnifiedPayment::Transaction.stub(:where).with(:payment_transaction_id => '123456').and_return([])
      end
      
      describe 'method calls' do
        it { UnifiedPayment::Transaction.should_receive(:where).with(:payment_transaction_id => '123456').and_return([]) }
        it { card_transaction.should_not_receive(:order) }

        after do
          send_request(:transaction_id => '123456')
        end
      end

      it 'renders js' do
        send_request(:transaction_id => '123456')
        response.body.should eq("alert('Could not find transaction')")
      end
    end
  end

  describe '#query_gateway' do
    def send_request(params = {})
      get :query_gateway, params.merge!(:use_route => 'spree', :format => 'js')
    end

    before do
      card_transaction.stub(:update_transaction_on_query).with("MyStatus").and_return(true)
      UnifiedPayment::Transaction.stub(:where).with(:payment_transaction_id => '123456').and_return([card_transaction])
      UnifiedPayment::Client.stub(:get_order_status).with(card_transaction.gateway_order_id, card_transaction.gateway_session_id).and_return({"orderStatus" => 'MyStatus'})
    end

    describe 'method calls' do
      it { UnifiedPayment::Client.should_receive(:get_order_status).with(card_transaction.gateway_order_id, card_transaction.gateway_session_id).and_return({"orderStatus" => 'MyStatus'}) }
      it { card_transaction.should_receive(:update_transaction_on_query).with('MyStatus').and_return(true) }
      after do
        send_request(:transaction_id => '123456')
      end
    end

    describe 'before filters' do
      describe 'load_transactions' do
        it { UnifiedPayment::Transaction.should_receive(:where).with(:payment_transaction_id => '123456').and_return([card_transaction]) }
      
        after do
          send_request(:transaction_id => '123456')
        end
      end
    end

    context 'approved status fetched' do
      before do
        UnifiedPayment::Client.stub(:get_order_status).with(card_transaction.gateway_order_id, card_transaction.gateway_session_id).and_return({"orderStatus" => 'APPROVED'})
        card_transaction.stub(:update_transaction_on_query).with('APPROVED').and_return(true)
      end

      it { card_transaction.should_receive(:update_transaction_on_query).with('APPROVED').and_return(true) }

      after do
        send_request(:transaction_id => '123456')
      end
    end

    context 'approved status not fetched' do
      it { card_transaction.should_receive(:update_transaction_on_query).with('MyStatus') }
      
      after do
        send_request(:transaction_id => '123456')
      end
    end
  end
end