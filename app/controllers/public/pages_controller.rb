module Public
  class PagesController < ApplicationController
    include PubliclyCached

    layout "home"

    before_action :set_cache_headers

    def show
      # A query string can override a route default in params. Not here.
      template = MARKETING_PAGES.fetch(request.path_parameters[:slug])

      respond_to do |format|
        format.html { render template }
      end
    end

    private

      def set_cache_headers
        cache_publicly(maxage: 1.hour)
      end
  end
end
