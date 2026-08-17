class App::Pages::SortController < AppController
  def create
    sort_by "updated"
  end

  def destroy
    sort_by "alpha"
  end

  private

    # A GET here would be prefetched: Turbo primes links on hover, so passing
    # the cursor over the sort buttons reordered the list.
    def sort_by(preference)
      cookies.permanent.encrypted[:pages_sort] = preference

      redirect_to app_pages_path
    end
end
