env "FEATURE"

feature :lexxy do |blog: nil|
  blog&.features.include?("lexxy")
end

feature :custom_css do |blog: nil|
  blog&.features.include?("custom_css")
end

feature :dynamic_open_graph do |blog: nil|
  blog&.features.include?("dynamic_open_graph")
end
