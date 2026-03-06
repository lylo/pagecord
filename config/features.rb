env "FEATURE"

feature :analytics_countries do |blog: nil|
  blog&.features.include?("analytics_countries")
end

feature :individual_email_delivery do |blog: nil|
  blog&.features.include?("individual_email_delivery")
end

feature :contact_form do |blog: nil|
  blog&.features.include?("contact_form")
end

feature :api do |blog: nil|
  blog&.features.include?("api")
end
