env "FEATURE"

feature :ses_newsletter_delivery do |user: nil, blog: nil|
  user&.features&.include?("ses_newsletter_delivery")
end
