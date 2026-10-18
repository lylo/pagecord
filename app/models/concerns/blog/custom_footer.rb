module Blog::CustomFooter
  extend ActiveSupport::Concern

  MAX_SIZE = 4.kilobytes
  ALLOWED_TAGS = %w[
    a b br div em hr i img li ol p small span strong u ul
  ].freeze
  ALLOWED_ATTRIBUTES = %w[
    href title target rel src alt width height loading class aria-label aria-hidden
  ].freeze

  included do
    validate :validate_custom_footer_html, if: -> { custom_footer_html.present? }
  end

  def custom_footer?
    custom_footer_html.present?
  end

  private

    def validate_custom_footer_html
      if custom_footer_html.bytesize > MAX_SIZE
        errors.add(:custom_footer_html, "is too large (maximum is #{MAX_SIZE / 1.kilobyte}KB)")
      elsif sanitize_custom_footer_html != custom_footer_fragment.to_html.strip
        problems = custom_footer_problems.presence || [ "contains invalid or potentially unsafe content" ]
        problems.each { errors.add(:custom_footer_html, it) }
      end
    end

    def sanitize_custom_footer_html
      sanitizer = Rails::HTML5::SafeListSanitizer.new
      sanitizer.sanitize(custom_footer_html.to_s, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES).strip
    end

    def custom_footer_fragment
      Nokogiri::HTML5.fragment(custom_footer_html.to_s)
    end

    def custom_footer_problems
      problems = []

      custom_footer_fragment.traverse do |node|
        if node.comment?
          problems << "has an HTML comment, which isn't allowed"
        elsif node.element? && ALLOWED_TAGS.exclude?(node.name)
          problems << "has <#{node.name}>, which isn't an allowed tag. Allowed tags are #{ALLOWED_TAGS.join(", ")}"
        elsif node.element?
          node.attribute_nodes.each do |attribute|
            if ALLOWED_ATTRIBUTES.exclude?(attribute.name)
              problems << "has the attribute `#{attribute.name}` on <#{node.name}>, which isn't allowed. Allowed attributes are #{ALLOWED_ATTRIBUTES.join(", ")}"
            elsif unsafe_footer_url?(attribute)
              problems << "has an unsafe URL in `#{attribute.name}` on <#{node.name}>. Use an http, https, mailto or relative URL"
            end
          end
        end
      end

      problems.uniq
    end

    def unsafe_footer_url?(attribute)
      return false unless Loofah::HTML5::SafeList::ATTR_VAL_IS_URI.include?(attribute.name)

      scheme = attribute.value[/\A\s*([^\/#?:\s]+):/, 1]
      scheme.present? && Loofah::HTML5::SafeList::ALLOWED_PROTOCOLS.exclude?(scheme.downcase)
    end
end
