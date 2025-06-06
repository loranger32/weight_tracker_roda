class SendEmailJob
  include SuckerPunch::Job

  def perform(mail)
    mail.deliver!
  end
end