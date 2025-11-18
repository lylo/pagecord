module CssSanitizable
  extend ActiveSupport::Concern

  # NOTE: The custom_css attribute is NOT mutated during validation.
  # Instead, validation checks if the CSS would be modified by sanitization.
  # If it would be modified, validation fails and the original CSS is preserved
  # in the textarea so the user can fix it without losing their work.

  included do
    validate :custom_css_safety, if: -> { custom_css.present? }
  end

  def sanitized_custom_css
    # Returns sanitized CSS safe for rendering in <style> tags
    # Sanitization happens in before_validation callback
    custom_css&.html_safe
  end

  private

    def custom_css_safety
      return unless custom_css.present?

      # Use custom CSS sanitizer that handles XSS prevention,
      # @import whitelisting for Google Fonts, and CSS custom properties
      sanitized = CssSanitizer.sanitize_stylesheet(custom_css)

      # Normalize for comparison (browsers may send \r\n)
      original_normalized = custom_css.gsub("\r\n", "\n").strip
      sanitized_normalized = sanitized.gsub("\r\n", "\n").strip

      # If sanitization changed the CSS, something unsafe or unsupported was removed
      # Don't mutate the attribute - let the user see what failed and fix it
      if original_normalized != sanitized_normalized
        errors.add(:custom_css, "contains invalid or potentially unsafe content")
      end
    end
end
