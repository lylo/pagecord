class ApplicationMailer < ActionMailer::Base
  default from: "Pagecord <hello@mailer.pagecord.com>",
          reply_to: "Pagecord <hello@pagecord.com>"

  layout "mailer"

  helper ImageHelper
end
