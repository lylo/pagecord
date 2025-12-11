class ApplicationMailbox < ActionMailbox::Base
    if Rails.env.development? && ENV["PAGECORD_RECIPIENT"].present?
      routing all: :posts
    else
      routing(
        /digest-reply-[a-z0-9]+@post\.pagecord\.com/i => :digest_reply,
        /^(?!digest-reply-).*@post\.pagecord\.com/i => :posts
      )
    end
end
