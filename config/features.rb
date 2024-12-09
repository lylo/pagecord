env "FEATURE"

feature :upvotes do |blog: nil|
  blog&.features.include?("upvotes")
end
