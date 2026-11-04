env "FEATURE"

feature :post_navigation do |user: nil, blog: nil|
  (user || blog&.user)&.features&.include?("post_navigation")
end

feature :ses_newsletter_delivery do |user: nil, blog: nil|
  user&.features&.include?("ses_newsletter_delivery")
end
