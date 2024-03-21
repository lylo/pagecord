class ApplicationMailbox < ActionMailbox::Base
  routing(/@post.pagecord.com/i => :posts)
end
