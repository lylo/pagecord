require "loops_sdk"

class MarketingAutomation::DeleteContactJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    return unless Rails.env.production?

    user = User.find(user_id)

    delete_from_loops(user) if user
  end

  private

    def delete_from_loops(user)
      response = LoopsSdk::Contacts.delete(email: user.email)

      Rails.logger.info "LoopsSdk::Contacts.delete response: #{response.inspect}"
      raise "LoopsSdk::Contacts.delete failed: #{response.inspect}" unless response["success"]
    end
end
