env "FEATURE"

feature :lexxy_ios do |blog: nil|
  blog&.features.include?("lexxy_ios")
end

feature :custom_html do |blog: nil|
  blog&.features.include?("custom_html")
end
