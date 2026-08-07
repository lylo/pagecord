module Blog::PostUrls
  extend ActiveSupport::Concern

  POST_URL_FORMATS = %w[flat prefix dated].freeze

  # Single path segments already routed ahead of /:prefix/:slug
  RESERVED_PREFIXES = %w[posts feed rss search pv email_subscribers upvotes].freeze

  included do
    before_validation :normalize_post_url_prefix

    validates :post_url_format, inclusion: { in: POST_URL_FORMATS }
    validates :post_url_prefix,
      presence: true,
      format: { with: Sluggable::SLUG_FORMAT, message: "can only contain lowercase letters, numbers, hyphens, and underscores" },
      exclusion: { in: RESERVED_PREFIXES, message: "is reserved and cannot be used" },
      if: -> { post_url_format == "prefix" }
  end

  # The posts archive lives at the folder when one is set, e.g. /notes
  def posts_list_path(params = {})
    path = post_url_format == "prefix" ? "/#{post_url_prefix}" : "/posts"
    params.present? ? "#{path}?#{params.to_query}" : path
  end

  private

    def normalize_post_url_prefix
      self.post_url_prefix = post_url_prefix.to_s.strip.downcase.gsub(/\A\/+|\/+\z/, "").presence
    end
end
