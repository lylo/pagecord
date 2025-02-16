env "FEATURE"

feature :exports do |blog: nil|
  blog&.features.include?("exports")
end
