class App::Settings::SocialLinksController < AppController
  def update
    if @blog.update(social_links_params)
      redirect_to app_settings_navigation_items_path, notice: "Social links updated"
    else
      redirect_to app_settings_navigation_items_path, alert: "Unable to update social links"
    end
  end

  private

  def social_links_params
    params.require(:blog).permit(social_links_attributes: [ :id, :platform, :url, :_destroy ])
  end
end
