module Blogs
  class RobotsController < Blogs::BaseController
    include RoutingHelper

    skip_before_action :verify_authenticity_token, only: [ :show ]
    skip_before_action :authenticate

    def show
      render formats: :text, content_type: "text/plain"
    end
  end
end
