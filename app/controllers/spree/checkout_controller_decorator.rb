Spree::CheckoutController.class_eval do
  before_filter :redirect_for_card_payment, :only => :update, :if => :payment_state?
  
  private

  def payment_state?
    params[:state] == 'payment'
  end

  def redirect_for_card_payment
    payment_method_id = params[:order][:payments_attributes][0][:payment_method_id] if params[:order] && params[:order][:payments_attributes]
    payment_method = Spree::PaymentMethod.where(:id => payment_method_id).first

    if payment_method.is_a?(Spree::PaymentMethod::UnifiedPaymentMethod)
      @order.update_from_params(params, permitted_checkout_attributes)
      redirect_to new_unified_transaction_path
    end
  end
end