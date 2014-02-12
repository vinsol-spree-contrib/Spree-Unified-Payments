require 'spec_helper'

describe Spree::CheckoutController do
  let(:user) { mock_model(Spree.user_class) }
  let(:role) { mock_model(Spree::Role) }
  let(:roles) { [role] }
  let(:order) { mock_model(Spree::Order) }
  let(:payment) { mock_model(Spree::Payment) }
  let(:variant) { mock_model(Spree::Variant, :name => 'test-variant') }

  before(:each) do
    controller.stub(:spree_current_user).and_return(user)
    user.stub(:generate_spree_api_key!).and_return(true)
    controller.stub(:authenticate_spree_user!).and_return(true)
    user.stub(:roles).and_return(roles)
    controller.stub(:authorize!).and_return(true)
    roles.stub(:includes).and_return(roles)
    role.stub(:ability).and_return(true)
    user.stub(:last_incomplete_spree_order).and_return(nil)
    controller.stub(:load_order).and_return(true)

    controller.stub(:ensure_order_not_completed).and_return(true)
    controller.stub(:ensure_checkout_allowed).and_return(true)
    controller.stub(:ensure_sufficient_stock_lines).and_return(true)
    controller.stub(:ensure_valid_state).and_return(true)
    controller.stub(:ensure_active_variants).and_return(true)

    controller.stub(:associate_user).and_return(true)
    controller.stub(:check_authorization).and_return(true)
    controller.stub(:object_params).and_return('object_params')
    controller.stub(:after_update_attributes).and_return(false)
    controller.instance_variable_set(:@order, order)
    order.stub(:has_checkout_step?).with('payment').and_return(true)
    order.stub(:payment?).and_return(false)
    order.stub(:update_attributes).and_return(false)
    order.stub(:update_attributes).with('object_params').and_return(false)
    @payments = [payment]
    @payments.stub(:reload).and_return(true)
    order.stub(:payments).and_return(@payments)
    order.stub(:next).and_return(true)
    order.stub(:completed?).and_return(false)
    order.stub(:state).and_return('payment')
  end

  describe '#redirect_for_card_payment' do
    def send_request(params = {})
      put :update, params.merge!({:use_route => 'spree'})
    end

    context 'if payment state' do
      before do
        @payment_method = mock_model(Spree::PaymentMethod, :type => 'Spree::PaymentMethod::UnifiedPaymentMethod')
        @payment_method.stub(:is_a?).with(Spree::PaymentMethod::UnifiedPaymentMethod).and_return(true)
      end

      context 'when params[:order].present?' do
        before { Spree::PaymentMethod.stub(:where).with(:id => '1').and_return([@payment_method]) }

        describe 'method calls' do
          it { order.should_receive(:update_attributes).with('object_params').and_return(false) }
          it { @payment_method.should_receive(:is_a?).with(Spree::PaymentMethod::UnifiedPaymentMethod).and_return(true) }
          it { Spree::PaymentMethod.should_receive(:where).with(:id => '1').and_return([@payment_method]) }
          it { order.should_not_receive(:update) }
          after { send_request({"order"=>{"payments_attributes"=>[{"payment_method_id"=>"1"}]}, "state"=>"payment"}) }
        end

        it 'should redirect to unified_payment#new' do
          send_request({"order"=>{"payments_attributes"=>[{"payment_method_id"=>"1"}]}, "state"=>"payment"})
          response.should redirect_to(new_unified_transaction_path)
        end
      end
      
      context 'when !params[:order].present?' do
        it 'should not redirect to unified_payment#new' do
          send_request({"state" => "payment"})
          response.should_not redirect_to(new_unified_transaction_path)
        end

        describe 'method calls' do
          it { order.should_receive(:update_attributes).with('object_params').exactly(1).times.and_return(true) }
          it { Spree::PaymentMethod.should_receive(:where).with(:id => nil).and_return([]) }
          after do
            send_request({"state" => "payment"})
          end
        end
      end

      context 'when !params[:order][:payments_attributes].present?' do
        it 'should not redirect to pay_by_card#new' do
          send_request({"state" => "payment"})
          response.should_not redirect_to(new_unified_transaction_path)
        end

        describe 'method calls' do
          it { order.should_not_receive(:update) }
          it { order.should_receive(:update_attributes).with('object_params').exactly(1).times.and_return(true) }
          it { Spree::PaymentMethod.should_receive(:where).with(:id => nil).and_return([]) }
          after do
            send_request({"order"=>{"payments_attributes"=>[{}]}, "state"=>"payment"})
          end
        end
      end
    end

    context 'if not payment state' do
      it { Spree::PaymentMethod.should_not_receive(:where).with(:id => '1') }
      it { controller.should_not_receive(:redirect_for_card_payment) }
      
      after do
        send_request({"order"=>{"payments_attributes"=>[{"payment_method_id"=>"1"}]}, "state"=>"delivery"})
      end
    end
  end
end