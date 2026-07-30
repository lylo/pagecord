class App::UpgradeBannersController < AppController
  def destroy
    dismiss_for_random_period

    respond_to do |format|
      format.html { redirect_to app_root_path }
      format.turbo_stream { render turbo_stream: turbo_stream.remove("upgrade_banner") }
    end
  end

  private

    def dismiss_for_random_period
      cookies.encrypted[:upgrade_banner_dismissed] = { value: true, expires: rand(14..30).days.from_now }
    end
end
