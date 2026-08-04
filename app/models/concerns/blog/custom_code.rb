module Blog::CustomCode
  extend ActiveSupport::Concern

  MAX_SIZE = 8.kilobytes
  HEAD_ELEMENTS = %w[ script style link meta noscript template ].freeze

  # Belong in a head, but Pagecord owns the title and a <base> would rewrite
  # every relative link on the blog, so neither is accepted.
  RESERVED_HEAD_ELEMENTS = {
    "title" => "Pagecord sets the page title for you. Change it under Blog Settings.",
    "base" => "<base> is not supported, because it would change every link on your blog."
  }.freeze

  included do
    normalizes :custom_head_html, :custom_body_html,
      with: -> { it.valid_encoding? ? it.gsub(/\r\n?/, "\n").strip.presence : it }

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
    custom_head_html.html_safe if custom_head_html.present? && custom_code_active?
  end

  def custom_body_html_for_render
    custom_body_html.html_safe if custom_body_html.present? && custom_code_active?
  end

  private

    def custom_head_html_valid
      return unless custom_code_valid?(:custom_head_html)

      if (disallowed = disallowed_head_node)
        errors.add(:custom_head_html, message_for(disallowed))
      end
    end

    def custom_body_html_valid
      custom_code_valid?(:custom_body_html)
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

    def message_for(node)
      return RESERVED_HEAD_ELEMENTS[node.name] if node.element? && RESERVED_HEAD_ELEMENTS.key?(node.name)

      subject = node.element? ? "<#{node.name}>" : "the text outside those tags"
      "can only contain #{HEAD_ELEMENTS.map { |tag| "<#{tag}>" }.to_sentence} tags. Move #{subject} to the body code instead"
    end

    def custom_code_valid?(name)
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
