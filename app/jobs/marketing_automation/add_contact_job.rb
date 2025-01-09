require "loops_sdk"

class MarketingAutomation::AddContactJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    return unless Rails.env.production?

    user = User.find(user_id)

    add_to_loops(user) if user
  end

  private

    # https://loops.so
    def add_to_loops(user)
      response = LoopsSdk::Contacts.create(
        email: user.email,
        properties: {
          username: user.blog.name,
          deliveryEmail: user.blog.delivery_email
        },
        mailing_lists: {
          cm3bk30v201in0ml49wza278w: user.marketing_consent
        })

      Rails.logger.info "LoopsSdk::Contacts.create response: #{response.inspect}"
      raise "LoopsSdk::Contacts.create failed: #{response.inspect}" unless response["success"]
    end
end
