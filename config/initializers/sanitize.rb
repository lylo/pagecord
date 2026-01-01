# Custom CSS sanitization for blog custom CSS feature
# Uses the Sanitize gem to prevent XSS while allowing safe CSS features

module CssSanitizer
  MAX_CSS_SIZE = 10_000 # 10KB limit to prevent DoS

  def self.sanitize_stylesheet(css)
    return "" if css.blank?

    # DoS protection: reject huge inputs
    return "" if css.bytesize > MAX_CSS_SIZE

    # Normalize encoding and line endings to prevent parser confusion
    css = css.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    css = css.gsub(/\r\n?/, "\n")

    # Extract CSS custom properties (--variables) to allow them explicitly
    # Sanitize doesn't support regex patterns, so we scan for them first
    custom_properties = css.scan(/--[\w-]+/).uniq

    # CSS Logical Properties for modern layouts and RTL support
    logical_properties = %w[
      margin-inline margin-inline-start margin-inline-end
      padding-inline padding-inline-start padding-inline-end
      margin-block margin-block-start margin-block-end
      padding-block padding-block-start padding-block-end
      border-inline border-inline-start border-inline-end
      border-block border-block-start border-block-end
      inset-inline inset-inline-start inset-inline-end
      inset-block inset-block-start inset-block-end
    ]

    # Build on RELAXED config: add @import support, Google Fonts, custom properties
    # Deep dup to avoid mutating frozen constant
    base_css_config = Sanitize::Config::RELAXED[:css].dup
    config = Sanitize::Config.freeze_config(
      Sanitize::Config::RELAXED.merge(
        css: base_css_config.merge(
          at_rules: [ "import" ],
          # Strict @import validation with regex to prevent bypass attempts
          import_url_validator: lambda { |url|
            url.match?(/\Ahttps:\/\/fonts\.(googleapis|gstatic)\.com\/[^\s"'<>]+\z/i)
          },
          properties: base_css_config[:properties] + custom_properties + logical_properties
        )
      )
    )

    sanitized = Sanitize::CSS.stylesheet(css, config)

    # Prevent XSS via </style> breakout when embedded in HTML
    # The Sanitize gem does not handle this context-aware escaping.
    # We escape the slash to <\/style which is valid CSS but breaks the HTML end-tag sequence.
    # See: https://github.com/rgrove/sanitize/issues/176
    sanitized.gsub(/<\/style/i, '<\\/style')
  end
end
