env "FEATURE"

feature :lexxy do |blog: nil|
  blog&.features.include?("lexxy")
end
