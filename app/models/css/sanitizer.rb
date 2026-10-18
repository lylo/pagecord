# Sanitizes user-provided CSS to prevent XSS while allowing safe features
# Uses the Sanitize gem for parsing and filtering

module Css
  module Sanitizer
    MAX_CSS_SIZE = 24576 # 24KB limit to prevent DoS

    ALLOWED_FONT_HOSTS = %w[
      fonts.googleapis.com
      fonts.gstatic.com
      fonts.bunny.net
    ].freeze

    AT_RULES = %w[ import layer supports ].freeze
    AT_RULES_WITH_STYLES = %w[ layer supports ].freeze

    class << self
      def sanitize_stylesheet(css)
        return "" if css.blank?
        return "" if css.bytesize > MAX_CSS_SIZE

        css = normalize_encoding(css)
        config = build_sanitize_config(css)
        sanitized = ::Sanitize::CSS.stylesheet(css, config)

        prevent_style_tag_breakout(sanitized)
      end

      # Says what sanitize_stylesheet would remove, and on which line, by walking
      # the same Crass tree that Sanitize::CSS walks.
      def problems(css)
        css = normalize_encoding(css.to_s)
        sanitizer = ::Sanitize::CSS.new(build_sanitize_config(css))

        problems = rule_problems(Crass.parse(css, preserve_comments: true), css, sanitizer)
        problems << "contains </style, which would end the stylesheet" if css.match?(/<\/style/i)
        problems
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
                at_rules: AT_RULES,
                import_url_validator: ->(url) { allowed_font_url?(url) },
                at_rules_with_styles: (base_css_config[:at_rules_with_styles] || []) + AT_RULES_WITH_STYLES,
                properties: base_css_config[:properties] + custom_properties + logical_properties + extra_properties
              )
            )
          )
        end

        def rule_problems(nodes, css, sanitizer, context = nil)
          preceded_by_property = false

          nodes.flat_map do |node|
            problems = node_problems(node, css, sanitizer, context, preceded_by_property)
            preceded_by_property = node[:node] == :property if %i[ property semicolon at_rule style_rule ].include?(node[:node])
            problems
          end
        end

        def node_problems(node, css, sanitizer, context, preceded_by_property)
          case node[:node]
          when :whitespace, :comment
            []
          when :style_rule
            rule_problems(node[:children], css, sanitizer, node[:selector][:value].strip)
          when :at_rule
            at_rule_problems(node, css, sanitizer)
          when :property
            property_problems(node, css, sanitizer)
          when :semicolon
            preceded_by_property ? [] : [ "has a stray semicolon on line #{line_at(css, node[:pos])}" ]
          else
            [ context ? "has something that isn't a declaration inside `#{context}`. Nested rules aren't supported, so write `#{context} .child { … }` as its own rule" : "has text that isn't a CSS rule" ]
          end
        end

        def at_rule_problems(node, css, sanitizer)
          name = node[:name].downcase
          line = line_at(css, node[:tokens].first[:pos])

          if sanitizer.config[:at_rules_with_styles].include?(name)
            rule_problems(Crass::Parser.parse_rules(node[:block], preserve_comments: true), css, sanitizer, "@#{name}")
          elsif sanitizer.config[:at_rules_with_properties].include?(name)
            rule_problems(Crass::Parser.parse_properties(node[:block], preserve_comments: true), css, sanitizer, "@#{name}")
          elsif name == "import"
            sanitizer.send(:at_rule!, node.dup) ? [] : [ "has an @import on line #{line} that isn't allowed. Only https URLs from #{ALLOWED_FONT_HOSTS.to_sentence} can be imported" ]
          elsif sanitizer.send(:at_rule!, node.dup).nil?
            [ "has @#{name} on line #{line}, which isn't an allowed at-rule" ]
          else
            []
          end
        end

        def property_problems(node, css, sanitizer)
          name = node[:name].downcase
          line = line_at(css, node[:tokens].first[:pos])

          if sanitizer.config[:properties].exclude?(name)
            [ "has `#{name}` on line #{line}, which isn't an allowed property" ]
          elsif sanitizer.send(:property!, node.dup).nil?
            [ "has a value for `#{name}` on line #{line} that isn't allowed: `#{node[:value].truncate(60)}`. URLs must be https, and expression() isn't supported" ]
          else
            []
          end
        end

        def line_at(css, position)
          css[0...position].count("\n") + 1
        end

        def allowed_font_url?(url)
          uri = URI.parse(url)
          uri.scheme == "https" && ALLOWED_FONT_HOSTS.include?(uri.host)
        rescue URI::Error
          false
        end

        def extra_properties
          %w[
            row-gap
            scroll-behavior
            -moz-osx-font-smoothing
            initial-letter
            -webkit-initial-letter
          ]
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
            inline-size min-inline-size max-inline-size
            block-size min-block-size max-block-size
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
