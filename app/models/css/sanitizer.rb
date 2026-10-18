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
        problems << "</style isn't allowed, because it would end the stylesheet." if css.match?(/<\/style/i)
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
          position = 0

          nodes.flat_map do |node|
            problems = node_problems(node, css, sanitizer, context, preceded_by_property, position)
            preceded_by_property = %i[ property error ].include?(node[:node]) unless %i[ whitespace comment ].include?(node[:node])
            position = end_of(node) || position
            problems
          end
        end

        # Crass gives no position for text it couldn't parse, so it is placed
        # where the node before it ended.
        def end_of(node)
          token = node[:raw] ? node : node[:tokens]&.last
          token[:pos] + token[:raw].length if token&.dig(:pos)
        end

        def node_problems(node, css, sanitizer, context, preceded_by_property, position)
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
            preceded_by_property ? [] : [ "Line #{line_at(css, node[:pos])} has a stray semicolon." ]
          else
            line = line_at(css, position)
            [ context ? "Line #{line}: nested rules aren't supported. Move what's inside #{context} into its own rule, such as #{context} .child { … }." : "Line #{line}: there's text that isn't part of a CSS rule." ]
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
            sanitizer.send(:at_rule!, node.dup) ? [] : [ "Line #{line}: @import can only load https URLs from #{ALLOWED_FONT_HOSTS.to_sentence}." ]
          elsif sanitizer.send(:at_rule!, node.dup).nil?
            [ "Line #{line}: @#{name} isn't supported." ]
          else
            []
          end
        end

        def property_problems(node, css, sanitizer)
          name = node[:name].downcase
          line = line_at(css, node[:tokens].first[:pos])

          if sanitizer.config[:properties].exclude?(name)
            [ "Line #{line}: the #{name} property isn't supported." ]
          elsif sanitizer.send(:property!, node.dup).nil?
            [ "Line #{line}: this value for #{name} isn't allowed: #{node[:value].truncate(60)}" ]
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
            place-items place-content place-self
            inset rotate scale isolation mix-blend-mode
            backdrop-filter -webkit-backdrop-filter
            scrollbar-width scrollbar-color scrollbar-gutter
            overscroll-behavior overscroll-behavior-x overscroll-behavior-y overscroll-behavior-block overscroll-behavior-inline
            scroll-margin scroll-margin-top scroll-margin-right scroll-margin-bottom scroll-margin-left
            scroll-margin-block scroll-margin-block-start scroll-margin-block-end
            scroll-margin-inline scroll-margin-inline-start scroll-margin-inline-end
            scroll-padding scroll-padding-top scroll-padding-right scroll-padding-bottom scroll-padding-left
            scroll-padding-block scroll-padding-block-start scroll-padding-block-end
            scroll-padding-inline scroll-padding-inline-start scroll-padding-inline-end
            scroll-snap-type scroll-snap-align scroll-snap-stop
            line-clamp hyphenate-character margin-trim -webkit-user-select
            print-color-adjust -webkit-print-color-adjust
            transition-behavior interpolate-size field-sizing position-anchor
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
