class DestroyUserJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    User.find(user_id).destroy
  end
end