class App::Posts::TabsController < App::BaseController
  # A GET here would be prefetched: Turbo primes links on hover, so passing
  # the cursor over a tab would switch it.
  def update
    cookies.permanent.encrypted[:posts_tab] = params[:tab] == "drafts" ? "drafts" : "published"

    redirect_to app_posts_path(search: params[:search].presence, tag: params[:tag].presence)
  end
end
