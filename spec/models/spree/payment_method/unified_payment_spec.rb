require 'spec_helper'

describe Spree::PaymentMethod::UnifiedPaymentMethod do
  let(:pending_payment) { mock_model(Spree::Payment, :state => 'pending') }
  let(:complete_payment) { mock_model(Spree::Payment, :state => 'complete') }
  let(:void_payment) { mock_model(Spree::Payment, :state => 'void') }
  before { @unified_payment = Spree::PaymentMethod::UnifiedPaymentMethod.new }
  it { @unified_payment.actions.should eq(["capture", "void"]) }
  it { @unified_payment.can_capture?(pending_payment).should be_true }
  it { @unified_payment.can_capture?(complete_payment).should be_false }
  it { @unified_payment.can_void?(pending_payment).should be_true }
  it { @unified_payment.can_void?(void_payment).should be_false }
  it { @unified_payment.source_required?.should be_false }
  it { @unified_payment.payment_profiles_supported?.should be_true }

  it 'voids a payment' do
    ActiveMerchant::Billing::Response.should_receive(:new).with(true, "", {}, {}).and_return(true)
    @unified_payment.void
  end

  it 'captures a payment' do
    ActiveMerchant::Billing::Response.should_receive(:new).with(true, "", {}, {}).and_return(true)
    @unified_payment.capture
  end
end