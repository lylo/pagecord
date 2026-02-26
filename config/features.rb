env "FEATURE"

feature :analytics_countries do |blog: nil|
  blog&.features.include?("analytics_countries")
end

feature :individual_email_delivery do |blog: nil|
  blog&.features.include?("individual_email_delivery")
end

feature :ses_newsletter_delivery do |blog: nil|
  blog&.features.include?("ses_newsletter_delivery")
end
