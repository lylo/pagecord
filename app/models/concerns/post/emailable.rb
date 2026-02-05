module Post::Emailable
  extend ActiveSupport::Concern

  def individually_sent?
    post_digests.individual.exists?
  end

  def individually_sendable?
    !is_page? && published? && kept? && !hidden? &&
      !individually_sent? &&
      blog.email_subscriptions_enabled? &&
      blog.user.subscribed? &&
      blog.email_subscribers.confirmed.exists?
  end

  def send_to_subscribers!
    digest = PostDigest.send_individual(self)
    digest&.deliver
  end
end
