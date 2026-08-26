class CustomDomains::VerificationsController < ApplicationController
  skip_forgery_protection
  skip_before_action :domain_check

  rate_limit to: 10, within: 1.minute, only: :show, by: -> { params[:domain] }

  def show
    domain = params[:domain]&.downcase
    return head :bad_request if domain.blank?

    blog = Blog.find_by_domain_with_www_fallback(domain)
    return head :unprocessable_content unless blog&.user&.custom_domain_access?

    head :ok
  end
end
