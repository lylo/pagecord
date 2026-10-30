env "FEATURE"

feature :post_navigation do |user: nil, blog: nil|
  (user || blog&.user)&.features&.include?("post_navigation")
end
