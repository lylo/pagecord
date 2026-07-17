module SpamPrevention
  extend ActiveSupport::Concern

  DEFAULT_MINIMUM_FORM_COMPLETION_TIME = 3.seconds

  included do
    before_action :form_complete_time_check, :honeypot_check, :suspicious_email_check, only: [ :create ]
  end

  # Override in controllers that need stricter timing (e.g., contact forms)
  def minimum_form_completion_time
    DEFAULT_MINIMUM_FORM_COMPLETION_TIME
  end

  private

    def honeypot_check
      if params[:email_confirmation].present?
        Rails.logger.warn "Honeypot field completed. Request blocked."
        reject_submission
      end
    end

    # The timestamp is signed and rendered into the form, so this is inert on
    # edge cached blog pages: a cached timestamp is always old enough to pass.
    # That's the surface Turnstile covers, and where no spam turns up. It does
    # the work on custom domains, which are never cached and can't use Turnstile.
    def form_complete_time_check
      timestamp = Rails.application.message_verifier(:spam_prevention).verified(params[:rendered_at])

      if timestamp.nil?
        Rails.logger.warn "Invalid or missing form token. Request blocked."
        return reject_submission
      end

      if (Time.current.to_i - timestamp) < minimum_form_completion_time
        Rails.logger.warn "Form completed too quickly. Request blocked."
        reject_submission
      end
    end

    def suspicious_email_check
      email = params.dig(:email_subscriber, :email) || params[:email]
      return if email.blank?

      if SuspiciousEmail.new(email).suspicious?
        Rails.logger.warn "Suspicious email blocked: #{email}"
        reject_submission
      end
    end

    # Override to say how a rejected submission responds. Shared with
    # TurnstileVerification, which is always included alongside this.
    def reject_submission
      head :forbidden
    end
end
