module BlogRoutingTest
  extend ActiveSupport::Concern

  # Sets the current test host to the blog's subdomain
  # After calling this, you can use regular Rails test helpers like:
  # get root_path, post posts_path, etc.
  def load_blog(subdomain)
    host! "#{subdomain}.example.com"
  end
end
