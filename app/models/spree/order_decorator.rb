Spree::Order.class_eval do
  has_many :unified_transactions, :class_name => 'UnifiedPayment::Transaction'
  def pending_card_transaction
    unified_transactions.pending.first
  end

  def release_inventory
    shipments.each do |shipment|
      shipment.cancel if shipment.inventory_units.any? { |iu| iu.pending == false }
    end
  end

  #over writing this method to release inventory units before being deleted in case reserved
  def create_proposed_shipments
    release_inventory
    shipments.destroy_all

    packages = Spree::Stock::Coordinator.new(self).packages
    packages.each do |package|
      shipments << package.to_shipment
    end

    shipments
  end

  def reason_if_cant_pay_by_card
    #[TODO] total == 0 can be written as total.zero?
    if total == 0 then 'Order Total is invalid'
    elsif completed? then 'Order already completed'
    elsif insufficient_stock_lines.present? then 'An item in your cart has become unavailable.'
    end
  end

  #overwriting this method under class Spree::Order to avoid reserve_stock twice in case order is from confirm state
  def finalize!
    touch :completed_at

    # lock all adjustments (coupon promotions, etc.)
    adjustments.each { |adjustment| adjustment.update_column('state', "closed") }

    # update payment states, and save
    updater.update_payment_state
    reserve_stock unless previous_states.last == :confirm

    updater.update_shipment_state
    save
    updater.run_hooks

    deliver_order_confirmation_email

    self.state_changes.create({
      previous_state: previous_states.last.to_s,
      next_state:     'complete',
      name:           'order' ,
      user_id:        self.user_id
    }, without_protection: true)
  end

  def reserve_stock
    shipments.each do |shipment|
      #to reserve stock only if it has not been reserved already.
      if shipment.inventory_units.any? { |inventory_unit| inventory_unit.pending == true }
        shipment.update!(self)
        shipment.finalize!
      end
    end
  end
end