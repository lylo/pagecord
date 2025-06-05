env "FEATURE"

feature :pages do |blog: nil|
  blog&.features.include?("pages")
end
