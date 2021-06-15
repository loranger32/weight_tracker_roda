class NewUserNotificationJob
  include SuckerPunch::Job

  def perform(mail)
    if mail.is_a? Mail::Message
      mail.deliver!
    else
      MailHelpers.send_mail_with_sendgrid(mail)
    end
  end
end
