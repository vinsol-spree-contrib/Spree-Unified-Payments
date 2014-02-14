module Spree
  class TransactionNotificationMailer < ActionMailer::Base
    helper 'transaction_notification_mail'
    # helper 'application'
    default :from => ADMIN_EMAIL

    def send_mail(card_transaction)
      @card_transaction = card_transaction
      @message = @card_transaction.xml_response.include?('<Message') ? Hash.from_xml(@card_transaction.xml_response)['Message'] : {}
      mail(
        :to => @card_transaction.user.email,
        :subject => "#{Spree::Config[:site_name]} - Unified Payment Transaction #{@card_transaction.status} notification"
      )
    end
  end
end