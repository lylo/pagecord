module Admin::ModerationHelper
  def content_moderation_count
    @content_moderation_count ||= Post.kept
                                      .moderation_flagged
                                      .published
                                      .joins(blog: :user)
                                      .where(users: { discarded_at: nil })
                                      .count
  end

  # Where the blog's links point, from the bio and navigation.
  def outbound_urls(blog)
    domain = Rails.application.config.x.domain
    sources = [ blog.bio.body&.to_html, *blog.navigation_items.map(&:link_url) ]

    sources.join(" ").scan(%r{https?://[^\s"'<>]+}i).uniq.reject do |url|
      host = url[%r{\Ahttps?://(?:www\.)?([^/?#]+)}i, 1].to_s.downcase
      host == domain || host.end_with?(".#{domain}")
    end
  end

  def blogs_to_review_count
    @blogs_to_review_count ||= Blog.unreviewed.count
  end
end
