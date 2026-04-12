env "FEATURE"

feature :analytics_countries do |blog: nil|
  blog&.features.include?("analytics_countries")
end
