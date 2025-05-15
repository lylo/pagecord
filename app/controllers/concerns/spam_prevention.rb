module SpamPrevention
  extend ActiveSupport::Concern

  included do
    rate_limit to: 1, within: 5.minutes, only: [ :create ]

    before_action :form_complete_time_check, :honeypot_check, :ip_reputation_check, only: [ :create ]
  end

  def honeypot_check
    unless params[:email_confirmation].blank?
      Rails.logger.warn "Honeypot field completed. Request blocked."
      fail
    end
  end

  def ip_reputation_check
    return true unless Rails.env.production?

    unless IpReputation.valid?(request.remote_ip)
      Rails.logger.warn "IP reputation check failed. Request blocked."
      fail
    end
  end

  def form_complete_time_check
    if params[:rendered_at].blank?
      fail
    end

    timestamp = params[:rendered_at].to_i
    form_complete_time = Time.current.to_i - timestamp

    if form_complete_time < 5.seconds
      Rails.logger.warn "Form completed too quickly. Request blocked."
      fail
    end
  end

  def fail
    head :forbidden
  end
end
