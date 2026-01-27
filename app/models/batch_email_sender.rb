class BatchEmailSender
  BATCH_SIZE = 50

  Result = Data.define(:subscriber, :success, :error_message)

  def initialize(provider: :postmark)
    @provider = provider
  end

  def send_batch(messages_with_subscribers)
    case @provider
    when :postmark
      send_via_postmark(messages_with_subscribers)
    else
      raise ArgumentError, "Unknown provider: #{@provider}. Supported: :postmark"
    end
  end

  private

    def send_via_postmark(messages_with_subscribers)
      api_token = Rails.application.config.action_mailer.postmark_settings&.dig(:api_token) || ENV["POSTMARK_API_TOKEN"]
      client = Postmark::ApiClient.new(api_token)
      messages = messages_with_subscribers.map(&:first)

      results = client.deliver_messages(messages)

      results.each_with_index.map do |result, index|
        subscriber = messages_with_subscribers[index].last
        Result.new(
          subscriber: subscriber,
          success: result[:error_code] == 0,
          error_message: result[:message]
        )
      end
    end
end
