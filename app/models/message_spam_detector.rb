class MessageSpamDetector
  Result = Struct.new(:status, :reason, keyword_init: true)

  attr_reader :result

  def initialize(name:, email:, message:, page_url: nil)
    @name = name
    @email = email
    @message = message
    @page_url = page_url
  end

  def detect
    return skip_result unless ENV["EMAIL_SPAM_DETECTION"]
    return error_result("Missing CleanTalk auth key") unless ENV["CLEANTALK_AUTH_KEY"]

    response = CleanTalk.check_message(
      email: @email,
      nickname: @name,
      message: @message,
      page_url: @page_url
    )

    parse_response(response)
  rescue StandardError => e
    Rails.logger.error("[MessageSpamDetector] Error: #{e.class} - #{e.message}")
    error_result("Detection error")
  end

  def spam?
    result&.status == :spam
  end

  private

    def skip_result
      @result = Result.new(status: :skipped, reason: "Email spam detection disabled")
    end

    def error_result(reason)
      @result = Result.new(status: :error, reason: reason)
    end

    def parse_response(response)
      status = response["allow"] == 0 ? :spam : :not_spam
      reason = response["comment"].to_s.strip.presence || "No reason provided"

      @result = Result.new(status: status, reason: reason)
    end
end
