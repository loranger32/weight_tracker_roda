module WeightTracker
  module MailHelpers
    include SendGrid

    def email_prefix
      "WeightTracker - "
    end

    def self.send_reset_password_email(config, scope)
      from = SendGrid::Email.new(email: config.send(:email_from))
      to = SendGrid::Email.new(email: config.account[:email])
      subject = email_prefix + "Password Reset Link"
      content = SendGrid::Content.new(type: 'text/html', value: scope.render("mails/reset-password-email"))
      mail = SendGrid::Mail.new(from, subject, to, content)

      sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      puts response.status_code
      puts response.body
      puts response.headers
    end
  end
end
