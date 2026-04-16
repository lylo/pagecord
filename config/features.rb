env "FEATURE"

feature :analytics_countries do |blog: nil|
  blog&.features.include?("analytics_countries")
end

feature :open_graph_image do |blog: nil|
  blog&.features.include?("open_graph_image")
end
