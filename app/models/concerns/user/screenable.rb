module User::Screenable
  extend ActiveSupport::Concern

  included do
    has_one :screening, dependent: :destroy
  end

  def screening_failed?
    screening&.failed?
  end

  def screen(ip:, user_agent:)
    return if ENV["CLEANTALK_AUTH_KEY"].blank?

    Rails.error.handle do
      create_screening!(failed_checks: { cleantalk: cleantalk_failure(ip, user_agent) }.compact)
    end
  end

  private

    def cleantalk_failure(ip, user_agent)
      response = CleanTalk.check_newuser(email: email, ip: ip, user_agent: user_agent, referrer: signup_referrer)
      response["codes"] if response["allow"].zero?
    end
end
