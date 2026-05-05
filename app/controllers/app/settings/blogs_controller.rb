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
        :locale,
        :show_metrics
      ]

      if @blog.user.subscribed?
        permitted_params += [ :custom_domain, :custom_robots_txt, :email_subscriptions_enabled, :show_subscription_in_header, :show_subscription_in_footer, :email_delivery_mode ]
      end

      if @blog.user.has_premium_access?
        permitted_params += [ :reply_by_email, :show_upvotes ]
      end

      attrs = params.require(:blog).permit(permitted_params)
      attrs[:custom_robots_txt] = nil if @blog.user.subscribed? && params[:use_custom_robots_txt] != "1"
      attrs
    end
end
