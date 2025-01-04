env "FEATURE"

feature :social_links do |blog: nil|
  blog&.features.include?("social_links")
end

feature :email_subscribers do |blog: nil|
  blog&.features.include?("email_subscribers")
end
