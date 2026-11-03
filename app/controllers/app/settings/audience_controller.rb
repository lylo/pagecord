class App::Settings::AudienceController < App::BaseController
  def show
  end

  def update
    if @blog.update(audience_params)
      redirect_to app_settings_path, notice: "Audience settings updated"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

    def audience_params
      permitted_params = [ :show_upvotes, :show_metrics ]

      if @blog.user.subscribed?
        permitted_params += [ :email_subscriptions_enabled, :email_delivery_mode, :show_subscription_in_header, :show_subscription_in_footer, :subscription_description ]
      end

      if @blog.user.has_premium_access?
        permitted_params += [ :reply_by_email, :comments_enabled ]
      end

      params.require(:blog).permit(permitted_params)
    end
end
