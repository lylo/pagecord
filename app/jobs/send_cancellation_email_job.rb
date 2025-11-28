class SendCancellationEmailJob < ApplicationJob
  def perform(user_id, subscriber:)
    user = User.find(user_id)

    if subscriber
      CancellationMailer.with(user: user).subscriber_cancellation.deliver_now
    else
      CancellationMailer.with(user: user).free_account_cancellation.deliver_now
    end
  end
end
