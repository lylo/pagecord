class App::Settings::BlogsController < AppController
  def index
  end

  def update
    if @blog.update(blog_params)
      if @blog.domain_changed?
        if @blog.custom_domain_previously_was.present?
          RemoveCustomDomainJob.perform_later(@blog.id, @blog.custom_domain_previously_was)
        end

        if @blog.custom_domain.present?
          AddCustomDomainJob.perform_later(@blog.id, @blog.custom_domain)
        end
      end

      @blog.posts.touch_all # cache busting

      redirect_to app_settings_path, notice: "Blog settings updated"
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

    def blog_params
      if @blog.user.subscribed?
        params.require(:blog).permit(
          :bio, :custom_domain, :title, :layout, :avatar,
          :email_subscriptions_enabled,
          :reply_by_email,
          :fediverse_author_attribution,
          social_links_attributes: [ :id, :platform, :url, :_destroy ]
        )
      else
        params.require(:blog).permit(
          :bio, :title, :layout,
          :fediverse_author_attribution,
          social_links_attributes: [ :id, :platform, :url, :_destroy ],
        )
      end
    end
end
