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
        errors.add(:custom_footer_html, "The footer can be up to #{MAX_SIZE / 1.kilobyte}KB.")
      elsif sanitize_custom_footer_html != custom_footer_fragment.to_html.strip
        problems = custom_footer_problems.presence || [ "Something in this HTML isn't supported or isn't safe." ]
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
          problems << "HTML comments aren't supported."
        elsif node.element? && ALLOWED_TAGS.exclude?(node.name)
          problems << "The <#{node.name}> tag isn't supported."
        elsif node.element?
          node.attribute_nodes.each do |attribute|
            if attribute.name == "style"
              problems << "Inline styles aren't supported. Add a class to the <#{node.name}> and style it in your custom CSS."
            elsif ALLOWED_ATTRIBUTES.exclude?(attribute.name)
              problems << "The #{attribute.name} attribute on <#{node.name}> isn't supported."
            elsif unsafe_footer_url?(attribute)
              problems << "The #{attribute.name} on <#{node.name}> needs to be an http, https, mailto or relative URL."
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
