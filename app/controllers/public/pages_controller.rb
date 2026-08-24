module Public
  class PagesController < ApplicationController
    # Kept in step with the slug constraint on the "/:slug" route.
    PAGES = %w[
      terms privacy faq brand
      pagecord-vs-about-me pagecord-vs-medium pagecord-vs-hey-world
      pagecord-vs-wordpress pagecord-vs-substack
      personal-website minimalist-blogging blogging-by-email
      blogger-alternative indie-blogging-platform
    ].freeze

    layout "home"

    # caches_page writes the rendered page into public/, so nothing here may
    # depend on the current user or a feature flag.
    caches_page :show

    def show
      render PAGES.fetch(PAGES.index(params[:slug])).tr("-", "_")
    end
  end
end
