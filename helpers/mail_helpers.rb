module WeightTracker
  module MailHelpers
    include SendGrid

    # IMPORTANT : It seems that the local variable 'mail' must be named 'mail' in order
    # for Sendgrid to process the sending correctly
    def self.send_mail_with_sendgrid(original_mail)
      from = SendGrid::Email.new(email: original_mail.from[0])
      to = SendGrid::Email.new(email: original_mail.to[0])
      subject = original_mail.subject
      content = SendGrid::Content.new(type: "text/html", value: original_mail.body.raw_source)
      mail = SendGrid::Mail.new(from, subject, to, content)
      sg = SendGrid::API.new(api_key: ENV["SENDGRID_API_KEY"])
      response = sg.client.mail._("send").post(request_body: mail.to_json)
      puts response.status_code
      puts response.body
      puts response.headers
    end
  end
end
