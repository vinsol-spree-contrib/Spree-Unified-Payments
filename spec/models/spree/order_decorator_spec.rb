require 'spec_helper'

describe Spree::Order do
  let(:user) { mock_model(Spree::User) }
  before(:each) do
    @order = Spree::Order.create!
  end

  it { should have_many :unified_transactions }

  describe "#pending_card_transaction" do
    before do
      UnifiedPayment::Transaction.any_instance.stub(:wallet_transaction).and_return(true)
      UnifiedPayment::Transaction.any_instance.stub(:enqueue_expiration_task).and_return(true)
      UnifiedPayment::Transaction.any_instance.stub(:assign_attributes_using_xml).and_return(true)
      UnifiedPayment::Transaction.any_instance.stub(:complete_order).and_return(true)
      UnifiedPayment::Transaction.any_instance.stub(:notify_user_on_transaction_status).and_return(true)
      @successful_card_transaction = @order.unified_transactions.create!(:status => 'successful', :payment_transaction_id => '1234', :amount => 100)
      @pending_card_transaction = @order.unified_transactions.create!(:status => 'pending', :payment_transaction_id => '1234', :amount => 100)
    end

    it { @order.pending_card_transaction.should eq(@pending_card_transaction) }
  end
  
  describe '#reserve_stock' do
    before do
      @pending_inventory_unit = mock_model(Spree::InventoryUnit, :pending => true)
      @order_shipment_with_pending_units = mock_model(Spree::Shipment)
      @order_shipment_with_pending_units.stub(:finalize!).and_return(true)
      @order_shipment_with_pending_units.stub(:update!).with(@order).and_return(true)
      @order_shipment_with_pending_units.stub(:inventory_units).and_return([@pending_inventory_unit])

      @unpending_inventory_unit = mock_model(Spree::InventoryUnit, :pending => false)
      @order_shipment_without_pending_units = mock_model(Spree::Shipment)
      @order_shipment_without_pending_units.stub(:inventory_units).and_return([@unpending_inventory_unit])
      @order.stub(:shipments).and_return([@order_shipment_with_pending_units, @order_shipment_without_pending_units])
    end

    it { @order.should_receive(:shipments).and_return([@order_shipment_with_pending_units, @order_shipment_without_pending_units]) }
    it { @order_shipment_with_pending_units.should_receive(:update!).with(@order).and_return(true) }
    it { @order_shipment_with_pending_units.should_receive(:finalize!).and_return(true) }
    it { @order_shipment_without_pending_units.should_not_receive(:update!).with(@order) }
    it { @order_shipment_without_pending_units.should_not_receive(:finalize!) }

    after do
      @order.reserve_stock
    end
  end

  describe '#create_proposed_shipments' do
    before do
      @order_shipment = mock_model(Spree::Shipment)
      inventory_unit = mock_model(Spree::InventoryUnit, :pending => false)
      @order_shipment.stub(:inventory_units).and_return([inventory_unit])
      @order_shipment.stub(:cancel).and_return(true)

      @pending_order_shipment = mock_model(Spree::Shipment)
      pending_inventory_unit = mock_model(Spree::InventoryUnit, :pending => true)
      @pending_order_shipment.stub(:inventory_units).and_return([pending_inventory_unit])

      @shipments = [@order_shipment, @pending_order_shipment]
      @shipments.stub(:destroy_all).and_return(true)
      @order.stub(:shipments).and_return(@shipments)
    end

    it { @order_shipment.should_receive(:cancel).and_return(true) }
    it { @pending_order_shipment.should_not_receive(:cancel) }
    it { @shipments.should_receive(:destroy_all).and_return(true) }

    after do
      @order.create_proposed_shipments
    end
  end

  
  describe '#release_inventory' do
    before do
      @pending_inventory_unit = mock_model(Spree::InventoryUnit, :pending => true)
      @order_shipment_with_pending_units = mock_model(Spree::Shipment)
      @order_shipment_with_pending_units.stub(:finalize!).and_return(true)
      @order_shipment_with_pending_units.stub(:update!).with(@order).and_return(true)
      @order_shipment_with_pending_units.stub(:inventory_units).and_return([@pending_inventory_unit])

      @unpending_inventory_unit = mock_model(Spree::InventoryUnit, :pending => false)
      @order_shipment_without_pending_units = mock_model(Spree::Shipment)
      @order_shipment_without_pending_units.stub(:inventory_units).and_return([@unpending_inventory_unit])
      @order_shipment_without_pending_units.stub(:cancel).and_return(true)
      @order.stub(:shipments).and_return([@order_shipment_with_pending_units, @order_shipment_without_pending_units])
    end

    it { @order_shipment_without_pending_units.should_receive(:cancel).and_return(true) }
    it { @order_shipment_with_pending_units.should_not_receive(:cancel) }

    after do
      @order.release_inventory
    end
  end

  describe '#reason_if_cant_pay_by_card' do
    before do
      @order.total = 100
      # @order.stub(:completed?).and_return(false)
    end

    context 'total is 0' do
      before { @order.total = 0 }
      it { @order.reason_if_cant_pay_by_card.should eq('Order Total is invalid') }
    end

    context 'order is completed' do
      before { @order.stub(:completed?).and_return(true) }
      it { @order.reason_if_cant_pay_by_card.should eq('Order already completed') }
    end

    context 'order has insufficient stock lines' do
      before { @order.stub(:insufficient_stock_lines).and_return([0]) }
      it { @order.reason_if_cant_pay_by_card.should eq('An item in your cart has become unavailable.') }
    end
  end

  describe 'finalize!' do
    before do
      @order.stub(:user_id).and_return(user.id)
      @adjustment = mock_model(Spree::Adjustment)
      @order.stub(:adjustments).and_return([@adjustment])
      @adjustment.stub(:update_column).with("state", "closed").and_return(true)
      @order.stub(:save).and_return(true)
      @order_updater = Spree::OrderUpdater.new(@order)
      @order.stub(:updater).and_return(@order_updater)
      @order_updater.stub(:update_shipment_state).and_return(true)
      @order_updater.stub(:update_payment_state).and_return(true)
      @order_updater.stub(:run_hooks).and_return(true)
      @state_changes = []
      @state_changes.stub(:create).with({:previous_state=>'confirm', :next_state=>"complete", :name=>"order", :user_id=>user.id}, {:without_protection=>true}).and_return(true)
      
      @order.stub(:state_changes).and_return(@state_changes)
      @order.stub(:previous_states).and_return([:delivery, :payment, :confirm])
      @order.stub(:reserve_stock).and_return(true)
    end

    it 'updates completed at' do
      @order.completed_at.should be_nil
      @order.finalize!
      @order.reload.completed_at.should_not be_nil
      @order.stub(:deliver_order_confirmation_email).and_return(true)
    end

    it 'udpates adjustments' do
      @adjustment.should_receive(:update_column).with("state", "closed").and_return(true)
      @order.finalize!
    end

    it 'saves self' do
      @order.should_receive(:save).and_return(true)
      @order.finalize!
    end

    it 'updates shipment states' do
      @order_updater.should_receive(:update_shipment_state).and_return(true)
      @order.finalize!
    end

    it 'updates payment states' do
      @order_updater.should_receive(:update_payment_state).and_return(true)
      @order.finalize!
    end

    it 'run hooks through updater' do
      @order_updater.should_receive(:run_hooks).and_return(true)
      @order.finalize!
    end

    it 'sends email' do
      @order.should_receive(:deliver_order_confirmation_email).and_return(true)
      @order.finalize!
    end

    it 'stores state changes' do
      @state_changes.should_receive(:create).with({:previous_state=>'confirm', :next_state=>"complete", :name=>"order", :user_id=>user.id}, {:without_protection=>true}).and_return(true)
      @order.finalize!
    end

    context 'when orders last state was confirm' do
      before do
        @order.stub(:previous_states).and_return([:delivery, :payment, :confirm])
      end

      it 'does not reserve stock' do
        @order.should_not_receive(:reserve_stock)
        @order.finalize!
      end
    end

    context 'when orders last state was not confirm' do
      before do
        @order.stub(:previous_states).and_return([:delivery, :payment])
        @state_changes.stub(:create).with({:previous_state=>"payment", :next_state=>"complete", :name=>"order", :user_id=>user.id}, {:without_protection=>true}).and_return(true)
      end

      it 'reserves stock' do
        @order.should_receive(:reserve_stock)
        @order.finalize!
      end
    end
  end
end