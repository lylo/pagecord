class CustomDomainsController < ApplicationController
  skip_forgery_protection
  skip_before_action :domain_check

  rate_limit to: 10, within: 1.minute, only: :verify

  def verify
    domain = params[:domain]&.downcase
    return head :bad_request if domain.blank?

    blog = Blog.find_by_domain_with_www_fallback(domain)
    return head :unprocessable_content unless blog&.user&.subscribed?

    head :ok
  end
end
