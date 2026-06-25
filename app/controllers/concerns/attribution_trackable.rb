module AttributionTrackable
  extend ActiveSupport::Concern

  SIGNUP_ATTRIBUTION_PARAMS = %w[utm_source utm_campaign].freeze
  SIGNUP_ATTRIBUTION_TTL = 24.hours

  included do
    before_action :capture_signup_attribution
  end

  private

    def capture_signup_attribution
      return unless DomainConstraints.default_domain?(request)
      return if signup_attribution.present?

      attribution = params.permit(*SIGNUP_ATTRIBUTION_PARAMS).to_h.compact_blank
      return if attribution.blank?

      session[:signup_attribution] = attribution.merge("expires_at" => SIGNUP_ATTRIBUTION_TTL.from_now.iso8601)
    end

    def signup_attribution
      attribution = session[:signup_attribution]
      return {} unless attribution.is_a?(Hash)

      expires_at = Time.zone.parse(attribution["expires_at"].to_s)
      if expires_at.blank? || expires_at.past?
        session.delete(:signup_attribution)
        return {}
      end

      attribution.slice(*SIGNUP_ATTRIBUTION_PARAMS)
    rescue ArgumentError
      session.delete(:signup_attribution)
      {}
    end
end
