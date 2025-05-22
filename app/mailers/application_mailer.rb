class ApplicationMailer < ActionMailer::Base
  default from: "Pagecord <no-reply@notifications.pagecord.com>",
          reply_to: "Pagecord <hello@pagecord.com>"

  layout "mailer"
end
