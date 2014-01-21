module Spree
  class TransactionNotificationMailer < ActionMailer::Base
    helper 'transaction_notification_mail'
    # helper 'application'
    default :from => ADMIN_EMAIL

    def send_mail(card_transaction)
      @card_transaction = card_transaction

      email = @card_transaction.user.email
      @order = @card_transaction.order
      @status = @card_transaction.status
      @message = @card_transaction.xml_response.include?('<Message') ? Hash.from_xml(@card_transaction.xml_response)['Message'] : {}
      mail(
        :to => email,
        :subject => "#{Spree::Config[:site_name]} - Unified Payment Transaction #{@status} notification"
      )
    end
  end
end