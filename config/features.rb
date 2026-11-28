env "FEATURE"

feature :ses_newsletter_delivery do |user: nil, blog: nil|
  user&.features&.include?("ses_newsletter_delivery")
end

feature :custom_css_file do |user: nil, blog: nil|
  blog&.user&.features&.include?("custom_css_file")
end
