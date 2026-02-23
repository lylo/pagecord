env "FEATURE"

feature :analytics_referrers do |blog: nil|
  blog&.features.include?("analytics_referrers")
end

feature :analytics_countries do |blog: nil|
  blog&.features.include?("analytics_countries")
end

feature :individual_email_delivery do |blog: nil|
  blog&.features.include?("individual_email_delivery")
end
