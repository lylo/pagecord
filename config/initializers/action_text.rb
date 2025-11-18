Rails.application.config.after_initialize do
  # Add custom attributes to ActionText's allowed list
  base_attributes = ActionText::ContentHelper.sanitizer.class.allowed_attributes
  attachment_attributes = ActionText::Attachment::ATTRIBUTES
  ActionText::ContentHelper.allowed_attributes = base_attributes + attachment_attributes + [
    "data-lightbox-full-url",
    "data-language",
    "data-highlight-language",
    "style",
    "controls",
    "poster",
    "playsinline"
  ]

  # Rails 8.2 changed ActionText to use HTML4 sanitizer instead of HTML5 sanitizer
  # The HTML4 sanitizer doesn't include several tags we need in its defaults
  # Add them directly to the sanitizer's class-level allowed_tags so ActionText picks them up
  Rails::HTML4::SafeListSanitizer.allowed_tags.merge([ "s", "u", "video", "source", "audio" ])
end
