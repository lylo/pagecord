env "FEATURE"

# The post editor's settings drawer, replacing the dropdown menu.
feature :post_settings_panel do |user: nil, blog: nil|
  user&.features&.include?("post_settings_panel")
end
