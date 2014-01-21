require 'spec_helper'

describe Spree::Order do
  
  before(:each) do
    @order = Spree::Order.create!
  end

  it { should have_many :unified_transactions }

  describe "#pending_card_transaction" do
    before do
      UnifiedPayment::Transaction.any_instance.stub(:wallet_transaction).and_return(true)
      UnifiedPayment::Transaction.any_instance.stub(:enqueue_expiration_task).and_return(true)
      UnifiedPayment::Transaction.any_instance.stub(:update_using_xml).and_return(true)
      UnifiedPayment::Transaction.any_instance.stub(:complete_order).and_return(true)
      UnifiedPayment::Transaction.any_instance.stub(:notify_user).and_return(true)
      @successful_card_transaction = @order.unified_transactions.create!(:status => 'successful', :payment_transaction_id => '1234')
      @pending_card_transaction = @order.unified_transactions.create!(:status => 'pending', :payment_transaction_id => '1234')
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

  describe '#finalize!' do
    context 'when orders last state was confirm' do
      before do
        @order.stub(:previous_states).and_return([:delivery, :payment, :confirm])
      end

      it { @order.should_not_receive(:reserve_stock) }
    end

    context 'when orders last state was not confirm' do
      before do
        @order.stub(:previous_states).and_return([:delivery, :payment])
      end

      it { @order.should_receive(:reserve_stock) }
    end

    after do
      @order.finalize!
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
end