class App::Settings::BlogsController < AppController
  def index
  end

  def update
    if @blog.update(blog_params)
      if @blog.domain_changed?
        if @blog.custom_domain.present?
          AddCustomDomainJob.perform_later(@blog.id, @blog.custom_domain)
        else
          RemoveCustomDomainJob.perform_later(@blog.id, @blog.custom_domain_previously_was)
        end
      end

      @blog.posts.touch_all # cache busting

      redirect_to app_settings_path, notice: "Appearance settings updated"
    else
      render :index
    end
  end

  private

    def blog_params
      if @blog.user.subscribed?
        params.require(:blog).permit(:bio, :custom_domain, :title, :avatar)
      else
        params.require(:blog).permit(:bio)
      end
    end
end
