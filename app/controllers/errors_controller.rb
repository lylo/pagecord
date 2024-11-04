class ErrorsController < ApplicationController
  layout "home"

  skip_before_action :domain_check

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

  def internal_error
    respond_to do |format|
      format.all do
        if custom_domain_request?
          render layout: "error", status: 500, formats: :html
        else
          render :internal_error, status: 500, formats: :html
        end
      end
    end
  end
end
