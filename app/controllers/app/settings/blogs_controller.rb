class App::Settings::BlogsController < App::BaseController
  def show
  end

  def update
    if @blog.update(blog_params)
      redirect_to app_settings_path, notice: "Blog settings updated"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

    def blog_params
      permitted_params = [
        :subdomain,
        :fediverse_author_attribution,
        :allow_search_indexing,
        :google_site_verification,
        :seo_title,
        :locale,
        :show_metrics,
        :external_links_in_new_tab,
        :show_upvotes,
        :use_password,
        :password,
        :post_url_format,
        :post_url_prefix
      ]

      if @blog.user.subscribed?
        permitted_params += [ :custom_domain, :custom_robots_txt, :use_custom_robots_txt, :email_subscriptions_enabled, :show_subscription_in_header, :show_subscription_in_footer, :email_delivery_mode ]
      end

      if @blog.user.has_premium_access?
        permitted_params += [ :reply_by_email, :comments_enabled ]
      end

      params.require(:blog).permit(permitted_params)
    end
end
