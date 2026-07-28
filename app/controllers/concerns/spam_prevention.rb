module SpamPrevention
  extend ActiveSupport::Concern

  include TurnstileHelper

  DEFAULT_MINIMUM_FORM_COMPLETION_TIME = 3.seconds

  included do
    before_action :form_complete_time_check, :honeypot_check, :suspicious_email_check,
                  :turnstile_check, only: [ :create ]
  end

  private

    # The email the visitor typed, for the suspicious email check. Override in
    # each controller; the concern can't know the form's param shape.
    def submitted_email
      nil
    end

    # Cached pages carry no session, so CSRF is skipped and the form carries a
    # token signed against the record it was rendered for instead. Controllers
    # that use one name it here and declare `before_action :form_token_check`
    # themselves, after the record is loaded.
    def signed_form_record
      nil
    end

    def form_token_purpose
      nil
    end

    def form_token_check
      record = signed_form_record
      return if record.nil?

      unless record.class.find_signed(params[:form_token], purpose: form_token_purpose) == record
        Rails.logger.warn "Form token / record mismatch. Request blocked."
        # Not reject_submission: a mismatched token is a malformed request rather
        # than a bot signal, and 422 is what Turbo renders back into the frame.
        head :unprocessable_entity
      end
    end

    # Override in controllers that need stricter timing (e.g., contact forms)
    def minimum_form_completion_time
      DEFAULT_MINIMUM_FORM_COMPLETION_TIME
    end

    # Override to say how a rejected submission responds.
    def reject_submission
      head :forbidden
    end

    # A failed challenge isn't the same as looking like a bot: it's usually a
    # real person who can retry. Override to say so.
    def reject_turnstile
      reject_submission
    end

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
      return if submitted_email.blank?

      if SuspiciousEmail.new(submitted_email).suspicious?
        Rails.logger.warn "Suspicious email blocked: #{submitted_email}"
        reject_submission
      end
    end

    def turnstile_check
      return unless turnstile_enabled?
      return if Turnstile.verify?(params["cf-turnstile-response"], remote_ip: request.remote_ip)

      Rails.logger.warn "Turnstile check failed. Request blocked."
      reject_turnstile
    end
end
