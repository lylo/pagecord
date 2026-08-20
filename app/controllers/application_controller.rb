class ApplicationController < ActionController::Base
  include Authentication, CustomDomainHelper

  before_action :domain_check

  helper_method :current_features, :blog_access_granted?

  def current_features
    Rails.features.for(user: Current.user, blog: @blog)
  end

  # The blog layout is shared with app-side previews, where the viewer is the
  # owner. Only the public blog gates its content, so it overrides this.
  def blog_access_granted?
    true
  end

  protected

    def redirect_to_app_home
      redirect_to root_url(host: app_host), allow_other_host: true
    end

  private

    def domain_check
      redirect_to_custom_domain_root if custom_domain_request?
    end

    def redirect_to_custom_domain_root
      redirect_to root_url(
        host: request.host,
        protocol: request.protocol,
        port: request.port
      ), allow_other_host: true
    end

    def app_host
      Rails.application.config.action_controller.default_url_options[:host]
    end
end
