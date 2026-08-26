module Blogs
  class RobotsController < Blogs::BaseController
    include RoutingHelper

    rate_limit to: 60, within: 1.minute

    skip_forgery_protection only: [ :show ]

    # A private blog still answers robots.txt – withholding it reads as "no
    # rules" to a crawler, when what we mean is "none of this".
    skip_before_action :require_blog_access

    def show
      render formats: :text, content_type: "text/plain"
    end
  end
end
