class App::Settings::BlogsController < AppController
  def index
    if @blog.custom_domain.present? && @blog.cloudflare_custom_hostname_id.present?
      @custom_hostname_status = CloudflareSaasApi.new(@blog).status
    end
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

      if @blog.user.has_premium_access?
        permitted_params += [ :reply_by_email, :show_upvotes ]
      end

      params.require(:blog).permit(permitted_params)
    end
end
