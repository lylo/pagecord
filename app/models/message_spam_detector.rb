class MessageSpamDetector
  Result = Struct.new(:status, :reason, keyword_init: true)

  MODEL = "gpt-4o-mini"

  attr_reader :result

  def initialize(name:, email:, message:)
    @name = name
    @email = email
    @message = message
    @access_token = ENV["OPENAI_ACCESS_TOKEN"] ||
                    Rails.application.credentials.dig(:openai_access_token)
    @client = OpenAI::Client.new(access_token: @access_token) if @access_token.present?
  end

  def detect
    return skip_result unless ENV["EMAIL_SPAM_DETECTION"].present?
    return error_result("Missing OpenAI access token") if @client.nil?

    response = @client.chat(
      parameters: {
        model: MODEL,
        temperature: 0.2,
        response_format: { type: "json_object" },
        messages: [ { role: "user", content: prompt } ]
      }
    )

    parse_response(response)
  rescue JSON::ParserError => e
    Rails.logger.warn("[MessageSpamDetector] JSON parse error: #{e.message}")
    error_result("Failed to parse AI response")
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
      content = response.dig("choices", 0, "message", "content")
      data = JSON.parse(content)

      status = data["classification"] == "spam" ? :spam : :not_spam
      reason = data["reason"].to_s.strip.presence || "No reason provided"

      @result = Result.new(status: status, reason: reason)
    end

    def prompt
      <<~PROMPT
        Analyze this contact form submission for spam. This is from a personal blogging platform where visitors can message blog authors.

        Name: #{@name}
        Email: #{@email}
        Message: #{@message}

        SPAM (classify as "spam"):
        - SEO service solicitations or link building offers
        - Commercial offers unrelated to the blog content
        - Phishing attempts or requests for personal information
        - Messages containing multiple promotional URLs
        - Generic marketing templates (web design, app development, lead generation)
        - Cryptocurrency or financial scheme promotions

        NOT SPAM (classify as "not_spam"):
        - Genuine reader feedback or questions about blog posts
        - Personal messages to the blog author
        - Messages with a single relevant link
        - Brief or casual messages (even if low-effort)
        - Collaboration or networking requests from real people

        Default to "not_spam" when in doubt.

        Return JSON only: {"classification": "spam" | "not_spam", "reason": "brief explanation"}
      PROMPT
    end
end
