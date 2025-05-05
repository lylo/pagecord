env "FEATURE"

feature :replies do |blog: nil|
  blog&.features.include?("replies")
end
