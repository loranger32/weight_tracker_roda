class NewUserNotificationJob
  include SuckerPunch::Job

  def perform(my_email, env)
    mail = Mail.new do
      from "weighttracker@example.com"
      to my_email
      subject "Weight Tracker - New User Signed Up"
      body "A new user signed up"
    end
    
    if env == :production
      WeightTracker::MailHelpers.send_mail_with_sendgrid(mail)
    else
      mail.deliver!
    end
  end
end
