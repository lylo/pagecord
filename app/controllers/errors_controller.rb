class ErrorsController < ApplicationController
  layout "home"

  skip_before_action :domain_check
  # A 500 must not depend on the session or the database either.
  skip_before_action :expire_legacy_session_cookie, :authenticate, only: :internal_error

  def not_found
    respond_to do |format|
      format.all do
        if custom_domain_request?
          render layout: "error", status: 404, formats: :html
        else
          render :not_found, status: 404, formats: :html
        end
      end
    end
  end

  def unacceptable
    respond_to do |format|
      format.all do
        if custom_domain_request?
          render layout: "error", status: 422, formats: :html
        else
          render :unacceptable, status: 422, formats: :html
        end
      end
    end
  end

  def too_many_requests
    respond_to do |format|
      format.all do
        if custom_domain_request?
          render layout: "error", status: 429, formats: :html
        else
          render :too_many_requests, status: 429, formats: :html
        end
      end
    end
  end

  # Reached through exceptions_app with the failed request's environment, so
  # anything that touched the request or a layout here has already failed at
  # least once. Serve the same static page Caddy uses when the app is down.
  def internal_error
    render file: Rails.public_path.join("error.html"), layout: false, status: 500, content_type: "text/html"
  end
end
