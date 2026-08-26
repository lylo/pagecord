# Editor content the default safe list would strip: strikethrough and
# underline, uploaded video with its player attributes, and inline styles.
# Global on purpose, so Action Text rendering, Html::Sanitize and the custom
# footer sanitiser all accept the same markup.
Rails::HTML5::Sanitizer.safe_list_sanitizer.allowed_tags += [ "s", "u", "video", "source" ]
Rails::HTML5::Sanitizer.safe_list_sanitizer.allowed_attributes += [ "style", "controls", "poster", "playsinline" ]
