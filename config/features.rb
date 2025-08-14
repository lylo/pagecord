env "FEATURE"

feature :admin_search do |blog: nil|
  blog&.features.include?("admin_search")
end
