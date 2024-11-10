require "loops_sdk"

class AccountCreatedJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    # FIXME only in prod!
    user = User.find(user_id)

    response = LoopsSdk::Contacts.create(
        email: user.email,
        properties: {
          username: user.username,
          deliveryEmail: user.delivery_email
        })

    Rails.logger.info "LoopsSdk::Contacts.create response: #{response.inspect}"
  end
end
