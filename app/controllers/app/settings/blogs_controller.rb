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
      permitted_params = [
        :fediverse_author_attribution,
        :allow_search_indexing
      ]

      permitted_params << [
        :custom_domain,
        :email_subscriptions_enabled,
        :reply_by_email,
        :show_upvotes
      ] if @blog.user.subscribed?

      params.require(:blog).permit(permitted_params)
    end
end
