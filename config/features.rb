env "FEATURE"

feature :comments do |user: nil, blog: nil|
  (blog&.user || user)&.features&.include?("comments")
end

feature :custom_code do |user: nil, blog: nil|
  (blog&.user || user)&.features&.include?("custom_code")
end
