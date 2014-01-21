Spree::CheckoutController.class_eval do
  before_filter :redirect_for_card_payment, :only => :update, :if => :payment_state?
  
  private

  def payment_state?
    params[:state] == 'payment'
  end

  def redirect_for_card_payment
    payment_method_id = params[:order][:payments_attributes][0][:payment_method_id] if params[:order] && params[:order][:payments_attributes]
    payment_method = Spree::PaymentMethod.where(:id => payment_method_id).first
    if payment_method.try(:type) == 'Spree::PaymentMethod::UnifiedPaymentMethod'
      @order.update_attributes(object_params)
      redirect_to new_unified_transaction_path
    end
    true
  end
end