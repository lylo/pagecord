class ErrorsController < ApplicationController
  layout "home"

  caches_page :not_found, :unacceptable, :internal_error

  def not_found
    respond_to do |format|
      format.all { render :not_found, status: 404, formats: :html }
    end
  end

  def unacceptable
    respond_to do |format|
      format.all { render :unacceptable, status: 422, formats: :html }
    end
  end

  def internal_error
    respond_to do |format|
      format.all { render :internal_error, status: 500, formats: :html }
    end
  end
end