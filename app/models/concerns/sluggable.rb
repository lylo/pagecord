module Sluggable
  extend ActiveSupport::Concern

  included do
    before_create :set_slug
  end

  private

    def set_slug
      return if slug.present?

      loop do
        self.slug = to_title_param
        break unless self.class.exists?(slug: slug)

        self.slug = "#{slug}-#{SecureRandom.hex(4)}"
      end
    end
end
