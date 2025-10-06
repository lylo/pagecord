env "FEATURE"

feature :lexxy do |blog: nil|
  blog&.features.include?("lexxy")
end

feature :home_page do |blog: nil|
  blog&.features.include?("home_page")
end
