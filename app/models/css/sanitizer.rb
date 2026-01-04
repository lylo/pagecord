# Sanitizes user-provided CSS to prevent XSS while allowing safe features
# Uses the Sanitize gem for parsing and filtering

module Css
  module Sanitizer
    MAX_CSS_SIZE = 2_000 # 2KB limit to prevent DoS

    ALLOWED_FONT_HOSTS = %w[
      fonts.googleapis.com
      fonts.gstatic.com
      fonts.bunny.net
    ].freeze

    class << self
      def sanitize_stylesheet(css)
        return "" if css.blank?
        return "" if css.bytesize > MAX_CSS_SIZE

        css = normalize_encoding(css)
        config = build_sanitize_config(css)
        sanitized = ::Sanitize::CSS.stylesheet(css, config)

        prevent_style_tag_breakout(sanitized)
      end

      private

        def normalize_encoding(css)
          css = css.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
          css.gsub(/\r\n?/, "\n")
        end

        def build_sanitize_config(css)
          custom_properties = css.scan(/--[\w-]+/).uniq
          base_css_config = ::Sanitize::Config::RELAXED[:css].dup

          ::Sanitize::Config.freeze_config(
            ::Sanitize::Config::RELAXED.merge(
              css: base_css_config.merge(
                at_rules: [ "import" ],
                import_url_validator: ->(url) { allowed_font_url?(url) },
                properties: base_css_config[:properties] + custom_properties + logical_properties
              )
            )
          )
        end

        def allowed_font_url?(url)
          uri = URI.parse(url)
          uri.scheme == "https" && ALLOWED_FONT_HOSTS.include?(uri.host)
        rescue URI::InvalidURIError
          false
        end

        def logical_properties
          %w[
            margin-inline margin-inline-start margin-inline-end
            padding-inline padding-inline-start padding-inline-end
            margin-block margin-block-start margin-block-end
            padding-block padding-block-start padding-block-end
            border-inline border-inline-start border-inline-end
            border-block border-block-start border-block-end
            inset-inline inset-inline-start inset-inline-end
            inset-block inset-block-start inset-block-end
          ]
        end

        def prevent_style_tag_breakout(css)
          # Escape </style> to prevent XSS when embedded in HTML
          # See: https://github.com/rgrove/sanitize/issues/176
          css.gsub(/<\/style/i, '<\\/style')
        end
    end
  end
end
