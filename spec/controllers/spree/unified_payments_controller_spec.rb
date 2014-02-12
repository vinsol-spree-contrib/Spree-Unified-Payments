require 'spec_helper'

describe Spree::UnifiedPaymentsController do
  
  let(:user) { mock_model(Spree.user_class) }
  let(:order) { mock_model(Spree::Order, :total => '12') }
  let(:variant) { mock_model(Spree::Variant, :name => 'test-variant') }

  before(:each) do
    user.stub(:generate_spree_api_key!).and_return(true)
    user.stub(:last_incomplete_spree_order).and_return(order)
    Spree::Config[:site_name] = "MyTestSite"
    controller.stub(:spree_current_user).and_return(user)
    controller.stub(:current_order).and_return(order)
  end

  context 'before going to gateway' do 
    before do
      order.stub(:user).and_return(user)
      order.stub(:completed?).and_return(false)
      order.stub(:insufficient_stock_lines).and_return([])
      order.stub(:pending_card_transaction).and_return(nil)
      order.stub(:inactive_variants).and_return([])
      order.stub(:reason_if_cant_pay_by_card).and_return(nil)
    end

    describe '#ensure_and_load_order' do
      def send_request(params = {})
        get :new, params.merge!({:use_route => 'spree'})
      end

      context 'when current order does not exist' do
        before do 
          controller.stub(:current_order).and_return(nil)
        end

        it 'does not call for reason_if_cant_pay_by_card on order' do
          order.should_not_receive(:reason_if_cant_pay_by_card)
          send_request
        end

        it 'response should redirect to cart' do
          send_request
          response.should redirect_to '/cart'
        end

        it 'sets flash message' do
          send_request
          flash[:error].should eq('Order not found')
        end
      end

      context 'when current order exists with no errors' do
        before { order.stub(:reason_if_cant_pay_by_card).and_return(nil) }
        
        it 'calls for reason_if_cant_pay_by_card on order' do
          order.should_receive(:reason_if_cant_pay_by_card).and_return(nil)
          send_request
        end

        it 'loads order' do
          send_request
          assigns(:order).should eq(order)
        end

        it 'sets no error message' do
          flash[:error].should be_nil
        end
      end

      context 'order exists but no valid' do
        before do 
          order.stub(:reason_if_cant_pay_by_card).and_return('Order is already completed.')
        end
        
        it 'calls for reason_if_cant_pay_by_card on order' do
          order.should_receive(:reason_if_cant_pay_by_card).and_return('Order is already completed.')
          send_request
        end

        it 'sets the flash message' do
          send_request
          flash[:error].should eq('Order is already completed.')
        end

        it 'gives a js response to redirect to cart' do
          send_request
          response.should redirect_to '/cart'
        end
      end
    end
    
    describe '#index' do
      before do
        @unified_payment = mock_model(UnifiedPayment::Transaction)
        @unified_payments = [@unified_payment]
        @unified_payments.stub(:order).with('updated_at desc').and_return(@unified_payments)
        @unified_payments.stub(:page).with('1').and_return(@unified_payments)
        @unified_payments.stub(:per).with(20).and_return(@unified_payments)
        user.stub(:unified_payments).and_return(@unified_payments)
      end

      def send_request(params = {})
        get :index, params.merge!({:use_route => 'spree'})
      end

      it { user.should_receive(:unified_payments).and_return(@unified_payments) }
      it { @unified_payments.should_receive(:order).with('updated_at desc').and_return(@unified_payments) }
      it { @unified_payments.should_receive(:page).with('1').and_return(@unified_payments) }
      it { @unified_payments.should_receive(:per).with(20).and_return(@unified_payments) }
      after { send_request(:page => '1') }
    end


    describe '#new' do

      def send_request(params = {})
        get :new, params.merge!({:use_route => 'spree'})
      end

      before { controller.stub(:generate_transaction_id).and_return(12345678910121) }

      describe 'method calls' do
        it { controller.should_receive(:generate_transaction_id).and_return(12345678910121) }
        
        after { send_request }
      end
      
      describe 'assigns' do
        before { send_request }

        it { session[:transaction_id].should eq(12345678910121) }
      end
    end

    describe '#create' do

      def send_request(params = {})
        post :create, params.merge!({:use_route => 'spree'})
      end

      before do
        session[:transaction_id] = '12345678910121'
        @gateway_response = Object.new
        UnifiedPayment::Transaction.stub(:create_order_at_unified).with(order.total, {:approve_url=>"http://test.host/unified_payments/approved", :cancel_url=>"http://test.host/unified_payments/canceled", :decline_url=>"http://test.host/unified_payments/declined", :description=>"Purchasing items from MyTestSite"}).and_return(@gateway_response)
        UnifiedPayment::Transaction.stub(:extract_url_for_unified_payment).with(@gateway_response).and_return('www.MyTestSite.com')
        controller.stub(:tasks_on_gateway_create_response).with(@gateway_response, '12345678910121').and_return(true)
      end

      context 'with a pending card transaction' do
        before do
          @pending_card_transaction = mock_model(UnifiedPayment::Transaction, :payment_transaction_id => '98765432110112')
          @pending_card_transaction.stub(:abort!).and_return(true)
          order.stub(:pending_card_transaction).and_return(@pending_card_transaction)
        end

        describe 'method calls' do
          it { order.should_receive(:pending_card_transaction).and_return(@pending_card_transaction) }
          it { @pending_card_transaction.should_receive(:abort!).and_return(true) }
        
          after { send_request }
        end
      end

      context 'with no card transaction' do
        before { order.stub(:pending_card_transaction).and_return(nil) }

        describe 'method calls' do
          it { order.should_receive(:pending_card_transaction).and_return(nil) }
          
          after { send_request }
        end
      end

      context 'when an order is successfully created at gateway' do
        
        describe 'method calls' do
          it { UnifiedPayment::Transaction.should_receive(:create_order_at_unified).with(order.total, {:approve_url=>"http://test.host/unified_payments/approved", :cancel_url=>"http://test.host/unified_payments/canceled", :decline_url=>"http://test.host/unified_payments/declined", :description=>"Purchasing items from MyTestSite"}).and_return(@gateway_response) }
          it { UnifiedPayment::Transaction.should_receive(:extract_url_for_unified_payment).with(@gateway_response).and_return('www.MyTestSite.com') }
          it { controller.should_receive(:tasks_on_gateway_create_response).with(@gateway_response, '12345678910121').and_return(true) }
          
          after { send_request }
        end
        
        describe 'assigns' do
          it 'payment_url' do
            send_request
            assigns(:payment_url).should eq("www.MyTestSite.com")
          end
        end
      end

      context 'when order not created at gateway' do
        
        before { UnifiedPayment::Transaction.stub(:create_order_at_unified).with(order.total, {:approve_url=>"http://test.host/unified_payments/approved", :cancel_url=>"http://test.host/unified_payments/canceled", :decline_url=>"http://test.host/unified_payments/declined", :description=>"Purchasing items from MyTestSite"}).and_return(false) }
        
        describe 'method calls' do
          it { UnifiedPayment::Transaction.should_receive(:create_order_at_unified).with(order.total, {:approve_url=>"http://test.host/unified_payments/approved", :cancel_url=>"http://test.host/unified_payments/canceled", :decline_url=>"http://test.host/unified_payments/declined", :description=>"Purchasing items from MyTestSite"}).and_return(false) }
          it { UnifiedPayment::Transaction.should_not_receive(:extract_url_for_unified_payment) }
          it { controller.should_not_receive(:tasks_on_gateway_create_response) }
          
          after { send_request }
        end
      end

      context 'before filter' do
        describe '#ensure_session_transaction_id' do
          context 'when no session transaction id' do
            before do
              session[:transaction_id] = nil
              send_request
            end

            it { flash[:error].should eq('No transaction id found, please try again') }
            it { response.body.should eq("top.location.href = 'http://test.host/checkout/payment'") }
          end

          context 'when session transaction_id present' do
            before { send_request }

            it { flash[:error].should be_nil }
            it { response.body.should eq("$('#confirm_payment').hide();top.location.href = 'www.MyTestSite.com'") }
          end
        end
      end
    end

    describe '#tasks_on_gateway_create_response' do
      def send_request(params = {})
        post :create, params.merge!({:use_route => 'spree'})
      end

      before do
        session[:transaction_id] = '12345678910121'
        order.stub(:reserve_stock).and_return(true)
        order.stub(:next).and_return(true)
        @gateway_response = {'Status' => 'status', 'Order' => { 'SessionID' => '12312', 'OrderID' => '123121', 'URL' => 'MyResponse'}}
        @transaction = UnifiedPayment::Transaction.new
        UnifiedPayment::Transaction.stub(:create_order_at_unified).with(order.total, {:approve_url=>"http://test.host/unified_payments/approved", :cancel_url=>"http://test.host/unified_payments/canceled", :decline_url=>"http://test.host/unified_payments/declined", :description=>"Purchasing items from MyTestSite"}).and_return(@gateway_response)
        UnifiedPayment::Transaction.stub(:extract_url_for_unified_payment).with(@gateway_response).and_return('www.MyTestSite.com')
        UnifiedPayment::Transaction.stub(:where).with(:gateway_session_id => '12312', :gateway_order_id => '123121', :url => 'MyResponse').and_return([@transaction])
        @transaction.stub(:save!).and_return(true)
      end

      describe 'method calls' do
        context 'when order state is payment' do
          before { order.stub(:state).and_return('payment') }
          it { order.should_receive(:reserve_stock).and_return(true) }
          it { order.should_receive(:next).and_return(true) }

          after { send_request }
        end

        context 'when order state is not payment' do
          it { order.should_receive(:reserve_stock).and_return(true) }
          it { order.should_not_receive(:next) }
          it { UnifiedPayment::Transaction.should_receive(:where).with(:gateway_session_id => '12312', :gateway_order_id => '123121', :url => 'MyResponse').and_return([@transaction]) }
          it { @transaction.should_receive(:assign_attributes).with(:user_id => order.user.try(:id), :payment_transaction_id => '12345678910121', :order_id => order.id, :gateway_order_status => 'CREATED', :amount => order.total, :currency => Spree::Config[:currency], :response_status => 'status', :status => 'pending').and_return(true) }
          it { @transaction.should_receive(:save!).and_return(true) }
          after { send_request }
        end
      end

      describe 'assigns' do
        before { send_request }

        it { session[:transaction_id].should be_nil }
      end
    end
  end

  context 'on return from gateway' do
    before do
      @card_transaction = mock_model(UnifiedPayment::Transaction)
      @card_transaction.stub(:approved_at_gateway?).and_return(false)
      @card_transaction.stub(:order).and_return(order)
      UnifiedPayment::Transaction.stub_chain(:where, :first).and_return(@card_transaction)
    end

    context 'as declined' do
      describe '#declined' do
        
        def send_request(params = {})
          post :declined, params.merge!({:use_route => 'spree'})
        end
        
        before do
          @card_transaction.stub(:assign_attributes).with(:status => 'unsuccessful', :xml_response => '<Message><Hash>Mymessage</Hash><ResponseDescription>Reason</ResponseDescription></Message>').and_return(true)
          @card_transaction.stub(:save).with(:validate => false).and_return(true)
        end

        describe 'method calls' do
          
          it { @card_transaction.should_receive(:order).and_return(order) }
          it { @card_transaction.should_receive(:assign_attributes).with(:status => 'unsuccessful', :xml_response => '<Message><Hash>Mymessage</Hash><ResponseDescription>Reason</ResponseDescription></Message>').and_return(true) }
          it { @card_transaction.should_receive(:save).with(:validate => false).and_return(true) } 
          
          after { send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash><ResponseDescription>Reason</ResponseDescription></Message>'}) }
        end

        it 'renders without layout' do
          send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash><ResponseDescription>Reason</ResponseDescription></Message>'})
          response.should render_template(:declined, :layout => false)
        end
      end
    end

    context 'as canceled' do
      def send_request(params = {})
        post :canceled, params.merge!({:use_route => 'spree'})
      end

      before do
        @card_transaction.stub(:assign_attributes).with(:status => 'unsuccessful', :xml_response => '<Message><Hash>Mymessage</Hash></Message>').and_return(true)
        @card_transaction.stub(:save).with(:validate => false).and_return(true)
      end

      context 'before filter' do
        describe '#load_on_redirect' do        
          
          context 'there is a card transaction for the response' do
            before { UnifiedPayment::Transaction.stub_chain(:where, :first).and_return(@card_transaction) }
            
            describe 'method calls' do
              it { @card_transaction.should_receive(:order).and_return(order) }
              it { controller.should_not_receive(:verify_authenticity_token) }

              after { send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash></Message>'}) }
            end
            
            describe 'assigns' do
              it 'card_transaction' do
                send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash></Message>'})
                assigns(:card_transaction).should eq(@card_transaction)
              end
            end
          end

          context 'there is no card transaction for the response' do
            before do
              UnifiedPayment::Transaction.stub_chain(:where, :first).and_return(nil)
              send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash></Message>'})
            end

            describe 'method calls' do
              it { flash[:error].should eq('No transaction. Please contact our support team.') }
              it { response.should redirect_to('/') }
            
              after { send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash></Message>'}) }
            end
            
            describe 'assigns' do
              it 'card_transaction' do
                send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash></Message>'})
                assigns(:card_transaction).should be_nil
              end
            end
          end
        end
      end

      describe '#canceled' do
        
        describe 'method calls' do
          it { @card_transaction.should_receive(:assign_attributes).with(:status => 'unsuccessful', :xml_response => '<Message><Hash>Mymessage</Hash></Message>').and_return(true) }
          it { @card_transaction.should_receive(:save).with(:validate => false).and_return(true) }
          it { controller.should_not_receive(:verify_authenticity_token) }

          after { send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash></Message>'}) }
        end

        it 'renders without layout' do
          send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash></Message>'})
          response.should render_template(:canceled, :layout => false)
        end
      end
    end

    describe '#approved' do      
      
      def send_request(params = {})
        post :approved, params.merge!({:use_route => 'spree'})
      end

      before do
        @card_transaction.stub(:expired_at?).and_return(false)
        @card_transaction.stub(:xml_response=).with('<Message><Hash>Mymessage</Hash><PurchaseAmountScr>200</PurchaseAmountScr></Message>').and_return(true)
        @card_transaction.stub(:status=).with("successful").and_return(true)
        @card_transaction.stub(:status=).with("unsuccessful").and_return(true)
        @card_transaction.stub(:save).with(:validate => false).and_return(true)
        order.stub(:paid?).and_return(true)
      end

      describe 'method calls' do
        it { @card_transaction.should_receive(:order).and_return(order) }
        it { controller.should_not_receive(:verify_authenticity_token) }
      
        after { send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash><PurchaseAmountScr>200</PurchaseAmountScr></Message>'}) }
      end

      context 'approved at gateway' do
        before { @card_transaction.stub(:approved_at_gateway?).and_return(true) }

        context 'payment made at gateway is not as in card transaction' do
          before { @card_transaction.stub(:amount).and_return(100) }
          it { controller.should_receive(:add_error).with("Payment made was not same as requested to gateway. Please contact administrator for queries.").and_return(true) }
          it { @card_transaction.should_receive(:status=).with('unsuccessful').and_return(true) }
        
          after { send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash><PurchaseAmountScr>200</PurchaseAmountScr></Message>'}) }
        end

        context 'payment made at gateway is same as in card transaction' do
          before { @card_transaction.stub(:amount).and_return(200) }
          context 'transaction has expired' do
            before { @card_transaction.stub(:expired_at?).and_return(true) }

            describe 'assigns' do
              before { send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash><PurchaseAmountScr>200</PurchaseAmountScr></Message>'}) }

              it { assigns(:transaction_expired).should be_true }
              it { assigns(:payment_made).should eq(200) }
            end

            describe 'method_calls' do
              it { controller.should_receive(:add_error).with('Payment was successful but transaction has expired. The payment made has been walleted in your account. Please contact administrator to help you further.').and_return(true) }
              it { @card_transaction.should_receive(:status=).with('successful').and_return(true) }

              after { send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash><PurchaseAmountScr>200</PurchaseAmountScr></Message>'}) }
            end
          end

          context 'transaction has not expired' do

            describe 'assigns' do
              before { send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash><PurchaseAmountScr>200</PurchaseAmountScr></Message>'}) }
      
              it { assigns(:transaction_expired).should be_false }
            end

            context 'order has not been paid or completed' do
              before do
                order.stub(:completed?).and_return(false)
                order.stub(:paid?).and_return(false)
              end
              
              it { @card_transaction.should_receive(:status=).with('successful').and_return(true) }
              
              after { send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash><PurchaseAmountScr>200</PurchaseAmountScr></Message>'}) }
            end

            context 'order already completed' do
              before do
                order.stub(:completed?).and_return(true)
                order.stub(:paid?).and_return(false)
              end

              it { @card_transaction.should_receive(:status=).with('successful').and_return(true) }
              it { controller.should_receive(:add_error).with('Order Already Paid Or Completed').and_return(true) }
            
              after { send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash><PurchaseAmountScr>200</PurchaseAmountScr></Message>'}) }
            end

            context 'order already paid' do
              it { controller.should_receive(:add_error).with('Order Already Paid Or Completed').and_return(true) }
              it { @card_transaction.should_receive(:status=).with('successful').and_return(true) }
 
              after { send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash><PurchaseAmountScr>200</PurchaseAmountScr></Message>'}) }
            end

            context 'order total is not same as card total' do
              before do
                order.stub(:completed?).and_return(false)
                order.stub(:paid?).and_return(false)
                order.stub(:total).and_return(100)
                @card_transaction.stub(:amount).and_return(200)
              end
              it { controller.should_receive(:add_error).with("Payment made is different from order total. Payment made has been walleted to your account.").and_return(true) }
              it { @card_transaction.should_receive(:status=).with('successful').and_return(true) }
              it { @card_transaction.should_receive(:save).with(:validate => false).and_return(true) }
              
              after { send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash><PurchaseAmountScr>200</PurchaseAmountScr></Message>'}) }
            end
          end
        end
      end

      context 'not approved at gateway' do
        before do
          @card_transaction.stub(:approved_at_gateway?).and_return(false)
        end

        describe 'method calls' do
          it { controller.should_receive(:add_error).with('Not Approved At Gateway').and_return(true) }
          it { @card_transaction.should_not_receive(:amount) }
          it { @card_transaction.should_not_receive(:status=) }
          it { order.should_not_receive(:paid?) }
          it { order.should_not_receive(:completed?) }
          
          after { send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash><PurchaseAmountScr>200</PurchaseAmountScr></Message>'}) }
        end

        it 'renders without layout' do
          send_request({:xmlmsg => '<Message><Hash>Mymessage</Hash><PurchaseAmountScr>200</PurchaseAmountScr></Message>'})
          response.should render_template(:approved, :layout => false)
        end
      end
    end
  end
end