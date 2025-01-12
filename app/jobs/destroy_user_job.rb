class DestroyUserJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    User.find(user_id).discard!

    MarketingAutomation::DeleteContactJob.perform_later(user_id)
  end
end
