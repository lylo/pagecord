class CustomDomainsController < ApplicationController
  skip_before_action :verify_authenticity_token, :domain_check

  def verify
    domain = params[:domain]&.downcase
    return head :bad_request if domain.blank?

    blog = Blog.find_by(custom_domain: domain)
    return head :not_found unless blog&.user&.subscribed?

    head :ok
  end
end
