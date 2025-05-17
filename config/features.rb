env "FEATURE"

feature :themes do |blog: nil|
  blog&.features.include?("themes")
end
