env "FEATURE"

feature :custom_css do |blog: nil|
  blog&.features.include?("custom_css")
end

feature :lexxy_ios do |blog: nil|
  blog&.features.include?("lexxy_ios")
end
