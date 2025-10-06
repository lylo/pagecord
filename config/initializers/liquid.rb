# Load custom Liquid tags
Dir[Rails.root.join("app/liquid/tags/**/*.rb")].each { |f| require f }

# Create a custom Liquid environment and register tags
BlogLiquid = Liquid::Environment.build do |env|
  env.register_tag("posts", Tags::PostsTag)
  env.register_tag("email_subscription", Tags::EmailSubscriptionTag)
  env.register_tag("tags", Tags::TagsTag)
end
