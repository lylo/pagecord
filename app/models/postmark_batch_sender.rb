class PostmarkBatchSender
  BATCH_SIZE = 50

  Result = Data.define(:subscriber, :success, :error_message)

  def initialize
    @api_token = Rails.application.config.action_mailer.postmark_settings&.dig(:api_token) || ENV["POSTMARK_API_TOKEN"]
  end

  def send_batch(messages_with_subscribers)
    client = Postmark::ApiClient.new(@api_token)
    messages = messages_with_subscribers.map(&:first)
    subscribers = messages_with_subscribers.map(&:last)

    client.deliver_messages(messages).zip(subscribers).map do |result, subscriber|
      Result.new(
        subscriber: subscriber,
        success: result[:error_code] == 0,
        error_message: result[:message]
      )
    end
  end
end
