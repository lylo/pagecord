env "FEATURE"

feature :lexxy do |blog: nil|
  blog&.features.include?("lexxy")
end

feature :home_page do |blog: nil|
  blog&.features.include?("home_page")
end

feature :custom_css do |blog: nil|
  blog&.features.include?("custom_css")
end
