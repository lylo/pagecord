module Blog::CustomCode
  extend ActiveSupport::Concern

  MAX_SIZE = 8.kilobytes
  HEAD_ELEMENTS = %w[ script style link meta noscript template ].freeze

  included do
    before_validation :normalize_custom_code
    validate :custom_head_html_valid, if: -> { custom_head_html.present? }
    validate :custom_body_html_valid, if: -> { custom_body_html.present? }
  end

  # Custom code is a paid feature, and unlike custom CSS or the footer it can
  # run scripts, so it stops rendering when the plan lapses rather than lingering
  # on a pagecord.com subdomain forever. The content is kept, so resubscribing
  # brings it straight back.
  def custom_code_active?
    custom_code_enabled? && user.subscribed?
  end

  def custom_head_html_for_render
    custom_head_html.html_safe if custom_code_active? && custom_head_html.present?
  end

  def custom_body_html_for_render
    custom_body_html.html_safe if custom_code_active? && custom_body_html.present?
  end

  private

    def normalize_custom_code
      normalize_custom_code_attribute(:custom_head_html)
      normalize_custom_code_attribute(:custom_body_html)
    end

    def normalize_custom_code_attribute(name)
      value = self[name]
      return if value.nil? || !value.valid_encoding?

      self[name] = value.gsub(/\r\n?/, "\n").strip.presence
    end

    def custom_head_html_valid
      return unless custom_code_size_valid?(:custom_head_html)

      if (disallowed = disallowed_head_node)
        errors.add(:custom_head_html, "can only contain #{HEAD_ELEMENTS.map { |tag| "<#{tag}>" }.to_sentence} tags. Move #{node_description(disallowed)} to the body code instead")
      end

      if custom_head_html.scan(/<script\b/i).size != custom_head_html.scan(%r{</script\s*>}i).size
        errors.add(:custom_head_html, "has an unclosed <script> tag")
      end
    end

    def custom_body_html_valid
      custom_code_size_valid?(:custom_body_html)
    end

    # Only the top level matters – whatever lives inside a script or template is
    # the author's business.
    def disallowed_head_node
      Nokogiri::HTML5.fragment(custom_head_html).children.find do |node|
        if node.element?
          HEAD_ELEMENTS.exclude?(node.name)
        else
          !node.comment? && node.text.present?
        end
      end
    end

    def node_description(node)
      node.element? ? "<#{node.name}>" : "the text outside those tags"
    end

    def custom_code_size_valid?(name)
      value = self[name]

      unless value.valid_encoding?
        errors.add(name, "must be valid UTF-8")
        return false
      end

      if value.bytesize > MAX_SIZE
        errors.add(name, "is too large (maximum is #{MAX_SIZE / 1.kilobyte}KB)")
        return false
      end

      true
    end
end
