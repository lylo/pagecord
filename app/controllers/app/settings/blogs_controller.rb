class App::Settings::BlogsController < AppController
  def index
  end

  def update
    on_demand_tls = ENV["ON_DEMAND_TLS"].present?

    if @blog.update(blog_params)
      if @blog.domain_changed?
        if @blog.custom_domain_previously_was.present?
          RemoveCustomDomainJob.perform_later(@blog.id, @blog.custom_domain_previously_was) unless on_demand_tls
        end

        if @blog.custom_domain.present?
          AddCustomDomainJob.perform_later(@blog.id, @blog.custom_domain) unless on_demand_tls
        end
      end

      redirect_to app_settings_path, notice: "Blog settings updated"
    else
      render :index, status: :unprocessable_entity
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
        :locale
      ]

      if @blog.user.subscribed?
        permitted_params += [ :custom_domain, :email_subscriptions_enabled, :show_subscription_in_header, :show_subscription_in_footer ]
      end

      if @blog.user.subscribed? || @blog.user.on_trial?
        permitted_params += [ :reply_by_email, :show_upvotes ]
      end

      params.require(:blog).permit(permitted_params)
    end
end
