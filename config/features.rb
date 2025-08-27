env "FEATURE"

feature :analytics do |blog: nil|
  blog&.features.include?("analytics")
end
