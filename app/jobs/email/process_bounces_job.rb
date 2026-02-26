class Email::ProcessBouncesJob < ApplicationJob
  queue_as :low

  QUEUE_URL = ENV["AWS_SES_BOUNCE_QUEUE_URL"]
  WAIT_TIME_SECONDS = 5
  MAX_MESSAGES = 10

  def perform
    return unless QUEUE_URL.present?

    loop do
      response = sqs_client.receive_message(
        queue_url: QUEUE_URL,
        max_number_of_messages: MAX_MESSAGES,
        wait_time_seconds: WAIT_TIME_SECONDS
      )

      break if response.messages.empty?

      response.messages.each do |sqs_message|
        process_message(sqs_message)
        sqs_client.delete_message(queue_url: QUEUE_URL, receipt_handle: sqs_message.receipt_handle)
      end
    end
  end

  private

    def process_message(sqs_message)
      body = JSON.parse(sqs_message.body)
      sns_message = JSON.parse(body["Message"])

      notification_type = sns_message["notificationType"]

      case notification_type
      when "Bounce"
        process_bounce(sns_message)
      when "Complaint"
        process_complaint(sns_message)
      else
        Rails.logger.info "Ignoring SES notification type: #{notification_type}"
      end
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse SES bounce notification: #{e.message}"
    end

    def process_bounce(notification)
      bounce = notification["bounce"]
      return unless bounce["bounceType"] == "Permanent"

      bounce["bouncedRecipients"].each do |recipient|
        email = recipient["emailAddress"]
        Email::Suppression.suppress!(
          email,
          reason: "bounce",
          bounce_type: bounce["bounceType"],
          diagnostic_code: recipient["diagnosticCode"]
        )

        update_event_status(notification, "bounced")
      end
    end

    def process_complaint(notification)
      notification["complaint"]["complainedRecipients"].each do |recipient|
        Email::Suppression.suppress!(recipient["emailAddress"], reason: "complaint")
      end

      update_event_status(notification, "complained")
    end

    def update_event_status(notification, status)
      message_id = notification.dig("mail", "messageId")
      return unless message_id

      event = Email::Event.find_by(message_id: message_id)
      event&.update!(status: status)
    end

    def sqs_client
      @sqs_client ||= Aws::SQS::Client.new(
        region: ENV.fetch("AWS_SES_REGION", "eu-west-2"),
        credentials: Aws::Credentials.new(
          ENV["AWS_SES_ACCESS_KEY_ID"],
          ENV["AWS_SES_SECRET_ACCESS_KEY"]
        )
      )
    end
end
