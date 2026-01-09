# Add custom tags and attributes to ActionText's allowed list
# Prepend to sanitizer_allowed_tags to always include our custom tags
# regardless of when Lexxy sets allowed_tags
module ActionTextCustomTags
  CUSTOM_TAGS = %w[s u mark].freeze
  CUSTOM_ATTRIBUTES = %w[data-lightbox-full-url data-highlight-language playsinline].freeze

  def sanitizer_allowed_tags
    super + CUSTOM_TAGS
  end

  def sanitizer_allowed_attributes
    super + CUSTOM_ATTRIBUTES
  end
end

ActiveSupport.on_load(:action_text_content) do
  ActionText::ContentHelper.prepend(ActionTextCustomTags)
end
