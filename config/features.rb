env "FEATURE"

feature :lexxy_ios do |blog: nil|
  blog&.features.include?("lexxy_ios")
end
