module App::FeedHelper
  def rss_token_for(user)
    user.blog.delivery_email.split("@").first
  end
end
