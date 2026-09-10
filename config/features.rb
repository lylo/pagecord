env "FEATURE"

# The tag management screen hanging off the posts index.
feature :tag_management do |user: nil, blog: nil|
  user&.features&.include?("tag_management")
end
