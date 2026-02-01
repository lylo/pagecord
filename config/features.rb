env "FEATURE"

feature :lexxy_ios do |blog: nil|
  blog&.features.include?("lexxy_ios")
end

feature :analytics_referrers do |blog: nil|
  blog&.features.include?("analytics_referrers")
end

feature :analytics_countries do |blog: nil|
  blog&.features.include?("analytics_countries")
end
