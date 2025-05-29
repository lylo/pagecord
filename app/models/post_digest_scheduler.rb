class PostDigestScheduler
  def self.run
    Blog.where(email_subscriptions_enabled: true).includes(:user).find_each(batch_size: 100).with_index do |blog, index|
      user = blog.user
      next unless user&.kept? && user.subscribed?

      Time.use_zone(user.timezone || "UTC") do
        if Time.current.hour == 8
          Rails.logger.info "Generating digest for blog #{blog.id} (#{blog.subdomain}) - local time: #{Time.current}"
          GeneratePostDigestJob.set(wait: index * 2.seconds).perform_later(blog.id)
        end
      end
    end
  end
end
