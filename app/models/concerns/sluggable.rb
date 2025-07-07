module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :set_slug
    validates :slug,
      presence: true,
      length: { maximum: 100 },
      format: {
        with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/,
        message: "can only contain lowercase letters, numbers, and single hyphens between words"
      },
      uniqueness: {
        scope: :blog_id,
        message: "This slug has already been taken. Please choose another one."
      }
  end

  private

    def set_slug
      if slug.blank? || title_changed?
        generate_slug
      end
    end

    def generate_slug
      temp_token = self.token.presence || SecureRandom.hex(4)
      base_slug = parameterized_title.presence || temp_token

      candidate_slug = base_slug
      while slug_taken?(candidate_slug)
        candidate_slug = "#{base_slug}-#{temp_token}"
        temp_token = SecureRandom.hex(4)
      end

      self.slug = candidate_slug
    end

    def slug_taken?(candidate)
      blog.posts.where.not(id: id).exists?(slug: candidate)
    end

    def parameterized_title
      parameterized = title.to_s.parameterize.truncate(100, omission: "") || ""

      # Remove trailing hyphens that might result from truncation
      parameterized.gsub(/-+\z/, "")
    end
end
