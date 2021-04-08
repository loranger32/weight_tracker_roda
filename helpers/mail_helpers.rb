module WeightTracker
  module MailHelpers
    include SendGrid

    def self.email_prefix
      "WeightTracker - "
    end

    def self.send_reset_password_email(rodauth)
      from = SendGrid::Email.new(email: rodauth.send(:email_from))
      to = SendGrid::Email.new(email: rodauth.account[:email])
      subject = email_prefix + "Password Reset Link"
      content = SendGrid::Content.new(type: 'text/html', value: rodauth.scope.render("mails/reset-password-email"))
      mail = SendGrid::Mail.new(from, subject, to, content)

      sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      puts response.status_code
      puts response.body
      puts response.headers
    end

    def self.send_password_changed_email(rodauth)
      from = SendGrid::Email.new(email: rodauth.send(:email_from))
      to = SendGrid::Email.new(email: rodauth.account[:email])
      subject = email_prefix + "Password Changed"
      content = SendGrid::Content.new(type: 'text/html', value: rodauth.scope.render("mails/change-password-notify"))
      mail = SendGrid::Mail.new(from, subject, to, content)

      sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      puts response.status_code
      puts response.body
      puts response.headers
    end

    def self.send_verify_account_email(rodauth)
      from = SendGrid::Email.new(email: rodauth.send(:email_from))
      to = SendGrid::Email.new(email: rodauth.account[:email])
      subject = email_prefix + "Verify Account"
      content = SendGrid::Content.new(type: 'text/html', value: rodauth.scope.render("mails/verify-account-email"))
      mail = SendGrid::Mail.new(from, subject, to, content)

      sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      puts response.status_code
      puts response.body
      puts response.headers
    end

    def self.send_unlock_account_email(rodauth)
      from = SendGrid::Email.new(email: rodauth.send(:email_from))
      to = SendGrid::Email.new(email: rodauth.account[:email])
      subject = email_prefix + "Unlock Account"
      content = SendGrid::Content.new(type: 'text/html', value: rodauth.scope.render("mails/unlock-account-email"))
      mail = SendGrid::Mail.new(from, subject, to, content)

      sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      puts response.status_code
      puts response.body
      puts response.headers
    end

    def self.send_verify_login_change_email(rodauth, new_email)
      from = SendGrid::Email.new(email: rodauth.send(:email_from))
      to = SendGrid::Email.new(email: new_email)
      subject = email_prefix + "Verify Email Change"
      locals = {old_email: rodauth.account[:email], new_email: new_email}
      content = SendGrid::Content.new(type: 'text/html',
                                      value: rodauth.scope.render("mails/verify-email-change-email",
                                                                  locals: locals))
      mail = SendGrid::Mail.new(from, subject, to, content)

      sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      puts response.status_code
      puts response.body
      puts response.headers
    end
  end
end
