class CancellationMailerPreview < ActionMailer::Preview
  def subscriber_cancellation
    user = User.first
    CancellationMailer.with(user: user).subscriber_cancellation
  end

  def free_account_cancellation
    user = User.first
    CancellationMailer.with(user: user).free_account_cancellation
  end
end
