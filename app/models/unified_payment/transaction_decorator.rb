UnifiedPayment::Transaction.class_eval do    
  attr_accessible :payment_transaction_id, :order_id, :status, :user_id
  # validates :payment_transaction_id, :presence => true

  belongs_to :order, :class_name => "Spree::Order"
  belongs_to :user, :class_name => "Spree::User"
  has_one :store_credit, :class_name => "Spree::StoreCredit"
  scope :pending, lambda { where :status => 'pending' }
  after_create :enqueue_expiration_task, :if => [:payment_transaction_id?]

  after_save :notify_user, :if => [:status_changed?, "status_was == 'pending'"]
  before_save :assign_attributes_using_xml, :if => [:status_changed?, "status != 'pending'"]
  after_save :complete_order, :if => [:status_changed?, :payment_valid_for_order?, "status == 'successful' && !order_inventory_released?"]
  after_save :wallet_transaction, :if => [:status_changed? ,"(!payment_valid_for_order? || order_inventory_released?) && status == 'successful'"]
  after_save :cancel_order, :if => [:status_changed?, "status == 'unsuccessful'"]
  after_save :release_order_inventory, :if => [:expired_at?, "expired_at_was == nil"]

  def payment_valid_for_order?
    !order.completed? && order.total == amount
  end

  def order_inventory_released?
    expired_at?
  end

  def abort!
    update_attribute(:expired_at, Time.now)
  end

  def pending?
    status == 'pending'
  end

  def wallet_transaction(transactioner = nil)
    associate_user if user.nil?
    store_credit_balance = user.store_credits_total + amount.to_f
    store_credit = build_store_credit(:balance => store_credit_balance, :user => user, :transactioner => (transactioner || user), :amount => amount.to_f, :reason => "transferred from transaction:#{payment_transaction_id}", :payment_mode => -1, :type => "Spree::Credit")
    store_credit.save!
  end

  private

  def associate_user
    associate_with_user = Spree::User.where(:email => order.email).first
    if associate_with_user.nil?
      associate_with_user = Spree::User.create_unified_transaction_user(order.email)
    end
    self.user = associate_with_user
    save!
  end

  def assign_attributes_using_xml
    if xml_response.include?('<Message')
      info_hash = Hash.from_xml(xml_response)['Message']
      {:pan= => 'PAN', :response_description= => 'ResponseDescription', :gateway_order_status= => 'OrderStatus', :order_description= => 'OrderDescription', :response_status= => 'Status', :merchant_id= => 'MerchantTranID', :approval_code= => 'ApprovalCode'}.each_pair do |attribute, xml_mapping|
        self.send(attribute, info_hash[xml_mapping])
      end
    end
  end

  def notify_user
    Spree::TransactionNotificationMailer.send_mail(self).deliver!
  end

  def release_order_inventory
    #unless needed to not release inventory when transaction expires after order completed via some other payment method before expire or abort
    order.release_inventory unless order.completed?
  end

  def complete_order
    if order.total == amount
      order.next!
      order.pending_payments.first.complete
    end
  end

  def cancel_order
    unless order.completed?
      order.pending_payments.first.update_attribute(:state, 'failed')
      order.release_inventory unless order_inventory_released?
    end
  end

  def enqueue_expiration_task
    Delayed::Job.enqueue(TransactionExpiration.new(id), { :run_at => TRANSACTION_LIFETIME.minutes.from_now })
  end
end
