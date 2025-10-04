module Sluggable
  extend ActiveSupport::Concern

  RESERVED_SLUGS = %w[posts feed].freeze

  included do
    before_validation :set_slug
    validates :slug,
      presence: true,
      length: { maximum: 100 },
      format: {
        with: /\A[a-z0-9]+([-_][a-z0-9]+)*\z/,
        message: "can only contain lowercase letters, numbers, hyphens, and underscores"
      },
      uniqueness: {
        scope: :blog_id,
        message: "This slug has already been taken. Please choose another one."
      },
      exclusion: {
        in: RESERVED_SLUGS,
        message: "is reserved and cannot be used"
      }
  end

  private

    def set_slug
      if slug.blank? || should_regenerate_slug?
        generate_slug
      end
    end

    def should_regenerate_slug?
      title_changed? && (new_record? || draft?)
    end

    def generate_slug
      temp_token = self.token.presence || SecureRandom.hex(4)
      base_slug = parameterized_title.presence || temp_token

      candidate_slug = base_slug
      while slug_taken?(candidate_slug)
        candidate_slug = "#{base_slug}-#{SecureRandom.hex(4)}"
      end

      self.slug = candidate_slug
    end

    def slug_taken?(candidate)
      RESERVED_SLUGS.include?(candidate) || blog.all_posts.where.not(id: id).exists?(slug: candidate)
    end

    def parameterized_title
      # remove apostrophes to avoid unwanted hyphens during parameterization
      parameterized = title.to_s.delete("'")

      # convert to URL-friendly form and cap at 100 chars
      parameterized = parameterized.parameterize.truncate(100, omission: "") || ""

      # Remove trailing hyphens that can result from truncation
      parameterized.gsub(/-+\z/, "")
    end
end
