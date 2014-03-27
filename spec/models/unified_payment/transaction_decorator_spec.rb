require 'spec_helper'

describe UnifiedPayment::Transaction do
  it { should belong_to(:user).class_name('Spree::User') }
  it { should belong_to(:order).class_name('Spree::Order') }

  it { should have_one(:store_credit).class_name('Spree::StoreCredit') }
  let(:order) { Spree::Order.create! }
  let(:user) { mock_model(Spree::User) }

  before do
    UnifiedPayment::Transaction.any_instance.stub(:assign_attributes_using_xml).and_return(true)
    UnifiedPayment::Transaction.any_instance.stub(:notify_user_on_transaction_status).and_return(true)
    UnifiedPayment::Transaction.any_instance.stub(:complete_order).and_return(true)
    UnifiedPayment::Transaction.any_instance.stub(:cancel_order).and_return(true)
    UnifiedPayment::Transaction.any_instance.stub(:wallet_transaction).and_return(true)
    UnifiedPayment::Transaction.any_instance.stub(:enqueue_expiration_task).and_return(true)
    UnifiedPayment::Transaction.any_instance.stub(:release_order_inventory).and_return(true)
    UnifiedPayment::Transaction.any_instance.stub(:payment_valid_for_order?).and_return(true)
  end

  context 'callbacks' do
    context 'after and before save' do
      context 'pending transaction on creation' do
        before do
          @pending_card_transaction = UnifiedPayment::Transaction.new(:status => 'pending', :payment_transaction_id => '1234', :amount => 100)
        end

        it { @pending_card_transaction.should_not_receive(:notify_user_on_transaction_status) }
        it { @pending_card_transaction.should_not_receive(:assign_attributes_using_xml) }
        it { @pending_card_transaction.should_not_receive(:complete_order) }
        it { @pending_card_transaction.should_not_receive(:cancel_order) }
        it { @pending_card_transaction.should_not_receive(:wallet_transaction) }
        it { @pending_card_transaction.should_not_receive(:release_order_inventory) }

        after do
          @pending_card_transaction.save!
        end
      end

      context 'pending to successful transaction' do
        before do
          @successful_card_transaction = UnifiedPayment::Transaction.new(:status => 'pending', :payment_transaction_id => '1234', :amount => 100)
          @successful_card_transaction.save!
          @successful_card_transaction.status = 'successful'
        end

        it { @successful_card_transaction.should_receive(:notify_user_on_transaction_status).and_return(true) }
        it { @successful_card_transaction.should_receive(:assign_attributes_using_xml).and_return(true) }
        it { @successful_card_transaction.should_not_receive(:release_order_inventory) }

        context 'order inventory released' do
          before do
            @successful_card_transaction.stub(:order_inventory_released?).and_return(true)
          end

          context 'payment valid for order' do
            it { @successful_card_transaction.should_receive(:wallet_transaction).and_return(true) }
            it { @successful_card_transaction.should_not_receive(:complete_order) }
            it { @successful_card_transaction.should_not_receive(:cancel_order) }
          end

          context 'payment not valid for order' do
            before { @successful_card_transaction.stub(:payment_valid_for_order?).and_return(false) }

            it { @successful_card_transaction.should_receive(:wallet_transaction).and_return(true) }
            it { @successful_card_transaction.should_not_receive(:complete_order) }
            it { @successful_card_transaction.should_not_receive(:cancel_order) }
          end
        end
        
        context 'order inventory not released and' do
          before { @successful_card_transaction.stub(:order_inventory_released?).and_return(false) }
          context 'payment valid for order' do
            it { @successful_card_transaction.should_receive(:complete_order).and_return(true) }
            it { @successful_card_transaction.should_not_receive(:wallet_transaction) }
          end

          context 'payment not valid for order' do
            before { @successful_card_transaction.stub(:payment_valid_for_order?).and_return(false) }
            it { @successful_card_transaction.should_receive(:wallet_transaction).and_return(true) }
            it { @successful_card_transaction.should_not_receive(:complete_order) }
          end
         end
        
        after do
          @successful_card_transaction.save!
        end
      end

      context 'pending to unsuccessful transaction' do
        before do
          @unsuccessful_card_transaction = UnifiedPayment::Transaction.new(:status => 'pending', :payment_transaction_id => '1234', :amount => 100)
          @unsuccessful_card_transaction.save!
          @unsuccessful_card_transaction.status = 'unsuccessful'
        end

        context 'order inventory released' do
          before do
            @unsuccessful_card_transaction.stub(:order_inventory_released?).and_return(true)
          end
          it { @unsuccessful_card_transaction.should_not_receive(:complete_order) }
        end

        it { @unsuccessful_card_transaction.should_receive(:notify_user_on_transaction_status).and_return(true) }
        it { @unsuccessful_card_transaction.should_receive(:assign_attributes_using_xml).and_return(true) }
        it { @unsuccessful_card_transaction.should_not_receive(:complete_order) }
        it { @unsuccessful_card_transaction.should_receive(:cancel_order).and_return(true) }
        it { @unsuccessful_card_transaction.should_not_receive(:release_order_inventory) }

        after do
          @unsuccessful_card_transaction.save!
        end
      end

      context 'expire transaction' do
        before do
          @pending_card_transaction = UnifiedPayment::Transaction.create!(:status => 'pending', :payment_transaction_id => '1234', :amount => 100)
          @expired_card_transaction = UnifiedPayment::Transaction.create!(:status => 'unsuccessful', :payment_transaction_id => '1234', :amount => 100)
          @expired_card_transaction.expired_at = Time.current
          @expired_card_transaction.save!
        end

        it 'should not call release_order_inventory when not expiring a card transaction' do
          @pending_card_transaction.should_not_receive(:release_order_inventory)
          @pending_card_transaction.update_attribute(:status, :successful)
        end

        it 'should not call release_order_inventory for expiring expired card transaction' do
          @expired_card_transaction.should_not_receive(:release_order_inventory)
          @expired_card_transaction.update_attribute(:expired_at, Time.now)
        end

        it 'should call release_order_inventory for expiring pending card transaction' do
          @pending_card_transaction.should_receive(:release_order_inventory).and_return(true)
          @pending_card_transaction.update_attribute(:expired_at, Time.now)
        end
      end
    end
  end

  context 'scopes' do
    describe 'pending' do
      before do
        @successful_card_transaction = UnifiedPayment::Transaction.create!(:status => 'successful', :payment_transaction_id => '1234', :amount => 100)
        @pending_card_transaction = UnifiedPayment::Transaction.create!(:status => 'pending', :payment_transaction_id => '1234', :amount => 100)
      end

      it { UnifiedPayment::Transaction.pending.should eq([@pending_card_transaction]) }
    end
  end

  describe '#order_inventory_released?' do
    before(:all) do 
      @expired_card_transaction = UnifiedPayment::Transaction.new
      @expired_card_transaction.expired_at = Time.now
      @pending_card_transaction = UnifiedPayment::Transaction.new
    end
    
    it { @expired_card_transaction.order_inventory_released?.should be_true }
    it { @pending_card_transaction.order_inventory_released?.should be_false }
  end

  describe '#assign_attributes_using_xml' do
    before do
      UnifiedPayment::Transaction.any_instance.unstub(:assign_attributes_using_xml)
      @card_transaction_with_message = UnifiedPayment::Transaction.create!(:payment_transaction_id => '123321', :amount => 100)
      @xml_response = '<Message><PAN>123XXX123</PAN><PurchaseAmountScr>200</PurchaseAmountScr><Currency>NGN</Currency><ResponseDescription>TestDescription</ResponseDescription><OrderStatus>OnTest</OrderStatus><OrderDescription>TestOrder</OrderDescription><Status>00</Status><MerchantTranID>12345654321</MerchantTranID><ApprovalCode>123ABC</ApprovalCode></Message>'
      @card_transaction_with_message.stub(:xml_response).and_return(@xml_response)
      @gateway_transaction = UnifiedPayment::Transaction.new
      @card_transaction_with_message.stub(:gateway_transaction).and_return(@gateway_transaction)
      @card_transaction_without_message = UnifiedPayment::Transaction.new
    end

    describe 'method calls' do
      it { @card_transaction_with_message.should_receive(:xml_response).and_return(@xml_response) }
      it { @xml_response.should_receive(:include?).with('<Message').and_return(true) } 
        
      after do
        @card_transaction_with_message.send(:assign_attributes_using_xml)
      end
    end

    describe 'assigns' do
      before { @card_transaction_with_message.send(:assign_attributes_using_xml) }
      it { @card_transaction_with_message.pan.should eq('123XXX123') }
      it { @card_transaction_with_message.response_description.should eq('TestDescription') }
      it { @card_transaction_with_message.gateway_order_status.should eq('OnTest') }
      it { @card_transaction_with_message.order_description.should eq('TestOrder') }
      it { @card_transaction_with_message.response_status.should eq('00') }
      it { @card_transaction_with_message.approval_code.should eq('123ABC') }
      it { @card_transaction_with_message.merchant_id.should eq('12345654321') }
    end
  end

  describe '#notify_user_on_transaction_status' do
    before do
      UnifiedPayment::Transaction.any_instance.unstub(:notify_user_on_transaction_status)
      @card_transaction = UnifiedPayment::Transaction.new(:status => 'pending', :payment_transaction_id => '1234', :amount => 100)
      @mailer_object = Object.new
      @mailer_object.stub(:deliver!).and_return(true)
      Spree::TransactionNotificationMailer.stub(:delay).and_return(Spree::TransactionNotificationMailer)
      Spree::TransactionNotificationMailer.stub(:send_mail).with(@card_transaction).and_return(@mailer_object)
    end

    context 'when previous state was not pending' do
      it { Spree::TransactionNotificationMailer.should_not_receive(:send_mail) }
    end

    context 'when previous state was pending' do
      before do
        @card_transaction.save!
        @card_transaction.status = 'successful'
      end

      it { Spree::TransactionNotificationMailer.should_receive(:delay).and_return(Spree::TransactionNotificationMailer) }
      it { Spree::TransactionNotificationMailer.should_receive(:send_mail).with(@card_transaction).and_return(@mailer_object) }
    end
    
    after do
      @card_transaction.save!
    end
  end

  describe '#complete_order' do
    before do
      UnifiedPayment::Transaction.any_instance.unstub(:complete_order)
      @card_transaction = UnifiedPayment::Transaction.new(:status => 'successful', :payment_transaction_id => '1234', :amount => '100')
      @card_transaction.stub(:order).and_return(order)
      order.stub(:next!).and_return(true)
      @payment = mock_model(Spree::Payment)
      @payment.stub(:complete).and_return(true)
      order.stub(:pending_payments).and_return([@payment])
      order.stub(:total).and_return(100)
    end

    it { order.should_receive(:next!).and_return(true) }
    it { order.should_receive(:pending_payments).and_return([@payment]) }
    it { @payment.should_receive(:complete).and_return(true) }
    
    after do
      @card_transaction.send(:complete_order)
    end
  end

  describe '#cancel_order' do
    before do
      UnifiedPayment::Transaction.any_instance.unstub(:cancel_order)
      @card_transaction = UnifiedPayment::Transaction.new(:status => 'unsuccessful', :payment_transaction_id => '1234', :amount => 100)
      @card_transaction.stub(:order).and_return(order)
      order.stub(:release_inventory).and_return(true)
      @payment = mock_model(Spree::Payment)
      @payment.stub(:update_attribute).with(:state, 'failed').and_return(true)
      order.stub(:pending_payments).and_return([@payment])
    end

    context 'when order is completed' do
      before do
        order.stub(:completed?).and_return(true)
      end

      it { order.should_not_receive(:release_inventory) }
      it { order.should_not_receive(:pending_payments) }
    
      after do
        @card_transaction.send(:cancel_order)
      end
    end

    context 'when order is not completed' do
      before do
        order.stub(:completed?).and_return(false)
      end

      context 'inventory released' do
        before { @card_transaction.stub(:order_inventory_released?).and_return(true) }
        it { order.should_not_receive(:release_inventory) }
      end

      context 'inventory not released' do
        it { order.should_receive(:release_inventory).and_return(true) }
      end

      it { order.should_receive(:pending_payments).and_return([@payment]) }
      it { @payment.should_receive(:update_attribute).with(:state, 'failed').and_return(true) }
      
      after do
        @card_transaction.send(:cancel_order)
      end
    end
  end
  
  describe '#release_order_inventory' do
    before do
      UnifiedPayment::Transaction.any_instance.unstub(:release_order_inventory)
      @order = mock_model(Spree::Order)
      @order.stub(:release_inventory).and_return(true)
      @card_transaction = UnifiedPayment::Transaction.new(:status => 'somestatus')
      @card_transaction.stub(:order).and_return(@order)
    end

    context 'when order is already completed' do
      before { @order.stub(:completed?).and_return(true) }
      it { @order.should_not_receive(:release_inventory) }
    end

    context 'when order is not completed' do
      before { @order.stub(:completed?).and_return(false) }
      it { @order.should_receive(:release_inventory) }
    end

    after do
      @card_transaction.send(:release_order_inventory)
    end
  end

  describe 'abort!' do
    before do
      @time_now = DateTime.strptime('2012-03-03', '%Y-%m-%d')
      Time.stub(:current).and_return(@time_now)
      @card_transaction = UnifiedPayment::Transaction.new(:status => 'somestatus', :payment_transaction_id => '1234', :amount => 100)
      @card_transaction.stub(:release_order_inventory).and_return(true)
    end

    it 'release inventory' do
      @card_transaction.should_receive(:release_order_inventory).and_return(true)
      @card_transaction.abort!
    end

    it 'assigns expired_at' do
      @card_transaction.abort!
      @card_transaction.reload.expired_at.should eq(@time_now.to_s)
    end
  end

  describe 'status checks for pening, unsuccessful and successful' do
    before do
      @successful_card_transaction = UnifiedPayment::Transaction.create!(:status => 'successful', :payment_transaction_id => '1234', :amount => 100)
      @pending_card_transaction = UnifiedPayment::Transaction.create!(:status => 'pending', :payment_transaction_id => '1234', :amount => 100)
      @unsuccessful_card_transaction = UnifiedPayment::Transaction.create!(:status => 'unsuccessful', :payment_transaction_id => '1234', :amount => 100)
    end

    it { @successful_card_transaction.pending?.should be_false }
    it { @successful_card_transaction.successful?.should be_true }
    it { @successful_card_transaction.unsuccessful?.should be_false }

    it { @unsuccessful_card_transaction.successful?.should be_false }
    it { @unsuccessful_card_transaction.pending?.should be_false }
    it { @unsuccessful_card_transaction.unsuccessful?.should be_true }

    it { @pending_card_transaction.pending?.should be_true } 
    it { @pending_card_transaction.successful?.should be_false } 
    it { @pending_card_transaction.unsuccessful?.should be_false } 
  end

  describe '#enqueue_expiration_task' do
    before do
      UnifiedPayment::Transaction.any_instance.unstub(:enqueue_expiration_task)
      @last_id = UnifiedPayment::Transaction.last.try(:id) || 0
      current_time = Time.current
      Time.stub(:current).and_return(current_time)
      @new_card_transaction = UnifiedPayment::Transaction.new(:status => 'pending')
      @new_card_transaction.stub(:id).and_return(123)
    end
    
    context 'when transaction id is present' do
      before { @new_card_transaction.payment_transaction_id = '1234' }
      it 'enqueue delayed job' do
        Delayed::Job.should_receive(:enqueue).with(TransactionExpiration.new(@new_card_transaction.id), { :run_at => TRANSACTION_LIFETIME.minutes.from_now }).and_return(true)
      end

      after do
        @new_card_transaction.save!
      end
    end

    context 'when transaction id is not present' do
      it 'does not enqueue delayed job' do
        Delayed::Job.should_not_receive(:enqueue).with(TransactionExpiration.new(@new_card_transaction.id), { :run_at => TRANSACTION_LIFETIME.minutes.from_now })
      end

      after do
        @new_card_transaction.save!
      end
    end
  end

  describe '#wallet_transaction' do
    before do
      UnifiedPayment::Transaction.any_instance.unstub(:wallet_transaction)
      @card_transaction = UnifiedPayment::Transaction.create!(:payment_transaction_id => '123454321', :amount => 200)
      @card_transaction.stub(:user).and_return(user)
      @card_transaction.stub(:order).and_return(order)
      user.stub(:store_credits_total).and_return(100)
      @store_credit_balance = user.store_credits_total + @card_transaction.amount.to_f
      @store_credit = Object.new
      @card_transaction.stub(:build_store_credit).with(:balance => @store_credit_balance, :user => user, :transactioner => user, :amount => @card_transaction.amount.to_f, :reason => "transferred from transaction:#{@card_transaction.payment_transaction_id}", :payment_mode => Spree::Credit::PAYMENT_MODE['Payment Refund'], :type => "Spree::Credit").and_return(@store_credit)
      @store_credit.stub(:save!).and_return(true)
    end

    it { @card_transaction.should_receive(:build_store_credit).with(:balance => @store_credit_balance, :user => user, :transactioner => user, :amount => @card_transaction.amount.to_f, :reason => "transferred from transaction:#{@card_transaction.payment_transaction_id}", :payment_mode => Spree::Credit::PAYMENT_MODE['Payment Refund'], :type => "Spree::Credit").and_return(@store_credit) }
    it { user.should_receive(:store_credits_total).and_return(100) }
    it { @store_credit.should_receive(:save!).and_return(true) }
    it { @card_transaction.should_not_receive(:associate_user) }
    
    context 'when user is nil' do
      before { user.stub(:nil?).and_return(true) }
      
      it { @card_transaction.should_receive(:associate_user).and_return(true) }
    end
    
    after do
      @card_transaction.wallet_transaction
    end
  end

  describe '#associate_user' do
    before do
      @card_transaction = UnifiedPayment::Transaction.create!(:payment_transaction_id => '123454321', :amount => 100)
      @card_transaction.stub(:order).and_return(order)
      order.stub(:email).and_return('test_user@baloo.com')
      @card_transaction.stub(:save!).and_return(true)
      @new_user = mock_model(Spree::User)
    end

    context 'when user with the order email exists' do
      before do 
        Spree::User.stub(:where).with(:email => order.email).and_return([user])
        @card_transaction.stub(:user=).with(user).and_return(true)
      end
      
      describe 'method calls' do
        it { Spree::User.should_receive(:where).with(:email => order.email).and_return([user]) }
        it { @card_transaction.should_receive(:user=).with(user).and_return(true) }
        after do
          @card_transaction.send(:associate_user)
        end
      end
    end

    context 'when user with the order email does not exist' do
      before do
        Spree::User.stub(:where).with(:email => order.email).and_return([]) 
        Spree::User.stub(:create_unified_transaction_user).with(order.email).and_return(user)
      end

      describe 'method calls' do
        it { Spree::User.should_receive(:where).with(:email => order.email).and_return([]) }
        it { Spree::User.should_receive(:create_unified_transaction_user).with(order.email).and_return(user) }
        
        after do
          @card_transaction.send(:associate_user)
        end
      end

      it 'associates a new user' do
        @card_transaction.user.should be_nil
        @card_transaction.send(:associate_user)
        @card_transaction.user.should eq(user)
      end
    end
  end

  describe '#update_transaction_on_query' do
    before { @card_transaction = UnifiedPayment::Transaction.create!(:payment_transaction_id => '123454321', :amount => 100) }
    
    context 'status is APPROVED' do
      it { @card_transaction.should_receive(:assign_attributes).with(:gateway_order_status => 'APPROVED', :status => 'successful').and_return(true) }
      it { @card_transaction.should_receive(:save).with(:validate => false).and_return(true) }
      after { @card_transaction.update_transaction_on_query('APPROVED') }
    end

    context 'status is APPROVED' do
      it { @card_transaction.should_receive(:assign_attributes).with(:gateway_order_status => 'MyStatus').and_return(true) }
      it { @card_transaction.should_receive(:save).with(:validate => false).and_return(true) }
      after { @card_transaction.update_transaction_on_query('MyStatus') }
    end
  end
end