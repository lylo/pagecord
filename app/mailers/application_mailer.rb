class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@notifications.pagecord.com",  reply_to: "hello@pagecord.com"

  layout "mailer"
end
