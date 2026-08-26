module Public
  class PagesController < ApplicationController
    layout "home"

    # caches_page writes the rendered page into public/, so nothing here may
    # depend on the current user or a feature flag.
    caches_page :show

    def show
      # A query string can override a route default in params. Not here.
      template = MARKETING_PAGES.fetch(request.path_parameters[:slug])

      respond_to do |format|
        format.html { render template }
      end
    end
  end
end
