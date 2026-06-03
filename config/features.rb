env "FEATURE"

feature :multiple_blogs do |user: nil, blog: nil|
  (user || blog&.user)&.features&.include?("multiple_blogs")
end
