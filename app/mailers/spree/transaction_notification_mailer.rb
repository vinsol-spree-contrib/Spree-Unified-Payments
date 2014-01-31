module Spree
  class TransactionNotificationMailer < ActionMailer::Base
    helper 'transaction_notification_mail'
    # helper 'application'
    default :from => ADMIN_EMAIL

    def send_mail(card_transaction)
      #[TODO] I am not sure if we really need @card_transaction. Because we are already defining other attributes
      # email variable is also not needed. we can assig this directly
      @card_transaction = card_transaction

      email = @card_transaction.user.email
      @order = @card_transaction.order
      @status = @card_transaction.status
      #[TODO] I guess we don't have to use xml_response anywhere. Only need to display this to admin.
      @message = @card_transaction.xml_response.include?('<Message') ? Hash.from_xml(@card_transaction.xml_response)['Message'] : {}
      mail(
        :to => email,
        :subject => "#{Spree::Config[:site_name]} - Unified Payment Transaction #{@status} notification"
      )
    end
  end
end