env "FEATURE"

feature :sender_email do |blog: nil|
  blog&.features.include?("sender_email")
end
