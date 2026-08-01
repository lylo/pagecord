# Add custom tags and attributes to ActionText's allowed list
# Prepend to sanitizer_allowed_tags to always include our custom tags
# regardless of when Lexxy sets allowed_tags
module ActionTextCustomTags
  CUSTOM_TAGS = %w[s u mark details summary].freeze
  CUSTOM_ATTRIBUTES = %w[data-lightbox-full-url data-highlight-language playsinline id open].freeze

  def sanitizer_allowed_tags
    super + CUSTOM_TAGS
  end

  def sanitizer_allowed_attributes
    super + CUSTOM_ATTRIBUTES
  end
end

ActiveSupport.on_load(:action_text_content) do
  ActionText::ContentHelper.prepend(ActionTextCustomTags)

  # Action Text describes an image only by its caption, which is always visible,
  # and has no hook for extra attachment attributes. Extending ATTRIBUTES is the
  # documented workaround (rails/rails discussion #54179) and is needed because
  # rendering rebuilds each attachment node, dropping anything off the list.
  # Read it back with attachment.full_attributes["alt"].
  attributes = (ActionText::Attachment::ATTRIBUTES + %w[alt]).freeze
  ActionText::Attachment.send(:remove_const, :ATTRIBUTES)
  ActionText::Attachment.const_set(:ATTRIBUTES, attributes)
end
