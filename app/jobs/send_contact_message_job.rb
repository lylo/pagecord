class SendContactMessageJob < ApplicationJob
  queue_as :default

  def perform(contact_message_id)
    contact_message = Blog::ContactMessage.find_by(id: contact_message_id)
    return unless contact_message

    if spam?(contact_message)
      Rails.logger.info("[SendContactMessageJob] Spam detected, destroying contact message #{contact_message.id}")
      contact_message.destroy!
      return
    end

    ContactMailer.with(contact_message: contact_message).new_message.deliver_now

    contact_message.destroy!
  end

  private

    def spam?(contact_message)
      detector = MessageSpamDetector.new(
        name: contact_message.name,
        email: contact_message.email,
        message: contact_message.message
      )
      detector.detect
      detector.spam?
    rescue => e
      Rails.logger.error("[SendContactMessageJob] Spam check failed: #{e.message}")
      false
    end
end
