env "FEATURE"

feature :open_graph_image do |blog: nil|
  blog&.features.include?("open_graph_image")
end
