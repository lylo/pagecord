module Post::Emailable
  extend ActiveSupport::Concern

  def emailed?
    post_digests.any? { |digest| digest.delivered_at.present? }
  end

  def individually_sent?
    post_digests.individual.exists?
  end

  def individually_sendable?
    !is_page? && published? && kept? && !hidden? &&
      !individually_sent? &&
      blog.individual? &&
      blog.email_subscriptions_enabled? &&
      blog.user.subscribed? &&
      blog.email_subscribers.confirmed.exists?
  end

  def send_to_subscribers!
    digest = PostDigest.generate_individual_for(self)
    digest&.deliver
  end
end
