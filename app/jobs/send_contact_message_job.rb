class SendContactMessageJob < ApplicationJob
  queue_as :default

  def perform(contact_message_id)
    contact_message = Blog::ContactMessage.find_by(id: contact_message_id)
    return unless contact_message

    ContactMailer.with(contact_message: contact_message).new_message.deliver_now

    contact_message.destroy!
  end
end
