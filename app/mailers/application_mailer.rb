class ApplicationMailer < ActionMailer::Base
  default from: "Pagecord <hello@remailer.pagecord.com>",
          reply_to: "Pagecord <hello@pagecord.com>"

  layout "mailer"

  helper ImageHelper
end
