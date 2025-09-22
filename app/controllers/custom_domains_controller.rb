class CustomDomainsController < ApplicationController
  skip_before_action :verify_authenticity_token, :domain_check

  def verify
    domain = params[:domain]&.downcase
    return head :bad_request if domain.blank?

    blog = Blog.find_by_domain_with_www_fallback(domain)
    return head :unprocessable_content unless blog&.user&.subscribed?

    head :ok
  end
end
