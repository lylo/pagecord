env "FEATURE"

feature :social_links do |blog: nil|
  blog&.features.include?("social_links")
end
