module Blogs
  class RobotsController < Blogs::BaseController
    include RoutingHelper

    rate_limit to: 60, within: 1.minute

    skip_forgery_protection only: [ :show ]
    skip_before_action :authenticate

    def show
      render plain: @blog.robots_txt(sitemap_url: sitemap_url_for(@blog)), content_type: "text/plain"
    end
  end
end
