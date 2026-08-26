class App::Pages::SortOrdersController < App::BaseController
  # A GET here would be prefetched: Turbo primes links on hover, so passing
  # the cursor over the sort buttons reordered the list.
  def update
    cookies.permanent.encrypted[:pages_sort] = params.dig(:sort_order, :by) == "updated" ? "updated" : "alpha"

    redirect_to app_pages_path
  end
end
