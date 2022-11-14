class SendEmailInProductionJob
  include SuckerPunch::Job

  def perform(mail)
    MailHelpers.send_mail_with_sendgrid(mail)
  end
end
