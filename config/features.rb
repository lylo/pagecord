env "FEATURE"

feature :individual_email_delivery do |blog: nil|
  blog&.features.include?("individual_email_delivery")
end

feature :api do |blog: nil|
  blog&.features.include?("api")
end
