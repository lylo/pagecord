module Blogs
  class RobotsController < Blogs::BaseController
    include RoutingHelper

    rate_limit to: 60, within: 1.minute

    skip_forgery_protection only: [ :show ]
    skip_before_action :authenticate

    # A protected blog still answers robots.txt – redirecting it to the unlock
    # page reads as "no rules" to a crawler, when what we mean is "none of this".
    skip_before_action :require_blog_password

    def show
      render formats: :text, content_type: "text/plain"
    end
  end
end
