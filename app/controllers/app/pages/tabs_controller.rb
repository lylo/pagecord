class App::Pages::TabsController < App::BaseController
  # A GET here would be prefetched: Turbo primes links on hover, so passing
  # the cursor over a tab would switch it.
  def update
    cookies.permanent.encrypted[:pages_tab] = params[:tab] == "drafts" ? "drafts" : "published"

    redirect_to app_pages_path
  end
end
