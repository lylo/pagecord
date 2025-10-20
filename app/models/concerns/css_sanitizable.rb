module CssSanitizable
  extend ActiveSupport::Concern

  # NOTE: The custom_css attribute is mutated during validation:
  # - Dangerous content (XSS, invalid @imports) is removed
  # - Whitespace is stripped
  # - Line endings are normalized
  # This ensures the stored CSS is safe and clean.

  included do
    before_validation :sanitize_custom_css, if: -> { custom_css_changed? }
    validate :custom_css_safety
  end

  def sanitized_custom_css
    # Returns sanitized CSS safe for rendering in <style> tags
    # Sanitization happens in before_validation callback
    custom_css&.html_safe
  end

  private

    def sanitize_custom_css
      return unless custom_css.present?

      # Store original for validation
      @original_custom_css = custom_css.dup

      # Use custom CSS sanitizer that handles XSS prevention,
      # @import whitelisting for Google Fonts, and CSS custom properties
      sanitized = CssSanitizer.sanitize_stylesheet(custom_css)

      # Strip leading/trailing whitespace before saving
      self.custom_css = sanitized.strip
    end

    def custom_css_safety
      return unless @original_custom_css.present?

      # Normalize line endings before comparing (browsers may send \r\n)
      original_normalized = @original_custom_css.gsub("\r\n", "\n").strip
      current_normalized = custom_css.to_s.gsub("\r\n", "\n").strip

      # If sanitization changed the CSS, something unsafe was removed
      if original_normalized != current_normalized
        errors.add(:custom_css, "contains invalid content")
      end
    end
end
