class App::Settings::StandardSiteController < AppController
  def show
  end

  def create
    unless @blog.user.has_premium_access?
      redirect_to app_settings_standard_site_path, alert: "Standard.site requires a premium subscription"
      return
    end

    session = StandardSite::Client.connect(
      handle: standard_site_params[:handle],
      app_password: standard_site_params[:app_password],
      pds_url: standard_site_params[:pds_url].presence || "https://bsky.social"
    )

    account = @blog.standard_site_account || @blog.build_standard_site_account
    account.assign_attributes(
      handle: session.fetch("handle", standard_site_params[:handle]),
      did: session.fetch("did"),
      pds_url: standard_site_params[:pds_url].presence || "https://bsky.social",
      access_jwt: session.fetch("accessJwt"),
      refresh_jwt: session.fetch("refreshJwt"),
      connected_at: Time.current,
      disconnected_at: nil
    )
    account.save!

    @blog.standard_site_publication || @blog.create_standard_site_publication!
    StandardSite::SyncPublicationJob.perform_later(@blog.id)

    redirect_to app_settings_standard_site_path, notice: "Bluesky connected"
  rescue StandardSite::Client::Error => e
    redirect_to app_settings_standard_site_path, alert: "Could not connect Bluesky: #{e.message}"
  end

  def destroy
    @blog.standard_site_account&.destroy
    @blog.standard_site_publication&.destroy
    StandardSite::Document.where(post: @blog.all_posts).destroy_all

    redirect_to app_settings_standard_site_path, notice: "Bluesky disconnected"
  end

  private

    def standard_site_params
      params.require(:standard_site).permit(:handle, :app_password, :pds_url)
    end
end
