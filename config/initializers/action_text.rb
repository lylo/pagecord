Rails.application.config.after_initialize do
  base_attributes = ActionText::ContentHelper.sanitizer.class.allowed_attributes
  attachment_attributes = ActionText::Attachment::ATTRIBUTES
  ActionText::ContentHelper.allowed_attributes = base_attributes + attachment_attributes + [ "data-lightbox-full-url", "data-language", "data-highlight-language" ]
end
