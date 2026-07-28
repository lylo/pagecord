class App::Posts::DetailsController < AppController
  def create
    show_details "on"
  end

  def destroy
    show_details "off"
  end

  private

    # A GET here would be prefetched: Turbo primes links on hover, so simply
    # passing the cursor over "Hide details" turned them off.
    def show_details(preference)
      cookies.permanent.encrypted[:posts_info] = preference

      redirect_to app_posts_path(search: params[:search].presence, page: params[:page])
    end
end
