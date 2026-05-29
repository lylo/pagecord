module Blog::CustomFooter
  extend ActiveSupport::Concern

  MAX_SIZE = 4.kilobytes
  ALLOWED_TAGS = %w[
    a b br div em i img li ol p span strong u ul
  ].freeze
  ALLOWED_ATTRIBUTES = %w[
    href title target src alt width height loading
  ].freeze

  included do
    validate :validate_custom_footer_html, if: -> { custom_footer_html.present? }
  end

  def custom_footer?
    user.has_premium_access? && custom_footer_html.present?
  end

  private

    def validate_custom_footer_html
      if custom_footer_html.bytesize > MAX_SIZE
        errors.add(:custom_footer_html, "is too large (maximum is #{MAX_SIZE / 1.kilobyte}KB)")
      elsif sanitize_custom_footer_html != custom_footer_html.strip
        errors.add(:custom_footer_html, "contains invalid or potentially unsafe content")
      end
    end

    def sanitize_custom_footer_html
      sanitizer = Rails::HTML5::SafeListSanitizer.new
      sanitizer.sanitize(custom_footer_html.to_s, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES).strip
    end
end
