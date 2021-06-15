class NewUserNotificationJob
  include SuckerPunch::Job

  def perform(mail, env)
    if env == :production
      WeightTracker::MailHelpers.send_mail_with_sendgrid(mail)
    else
      mail.deliver!
    end
  end
end
