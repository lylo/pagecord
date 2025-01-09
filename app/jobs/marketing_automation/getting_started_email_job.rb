require "loops_sdk"

class MarketingAutomation::GettingStartedEmailJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    return unless Rails.env.production?

    user = User.find(user_id)

    send_getting_started_event(user) if user.marketing_consent
  end

  private

    # https://loops.so
    def send_getting_started_event(user)
      response = LoopsSdk::Events.send(
        event_name: "getting_started",
        email: user.email
      )
      Rails.logger.info "LoopsSdk::Events.send response: #{response.inspect}"
      raise "LoopsSdk::Events.send failed: #{response.inspect}" unless response["success"]
    end
end
