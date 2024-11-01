class ApplicationMailbox < ActionMailbox::Base
  if Rails.env.development? && ENV["PAGECORD_RECIPIENT"].present?
    routing all: :posts
  else
    routing(/@post.pagecord.com/i => :posts)
  end
end
