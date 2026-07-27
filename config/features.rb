env "FEATURE"

feature :comments do |user: nil, blog: nil|
  (blog&.user || user)&.features&.include?("comments")
end
