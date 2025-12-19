env "FEATURE"



feature :custom_css do |blog: nil|
  blog&.features.include?("custom_css")
end
