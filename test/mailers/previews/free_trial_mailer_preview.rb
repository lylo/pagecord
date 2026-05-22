class FreeTrialMailerPreview < ActionMailer::Preview
  def trial_ended
    user = User.first
    FreeTrialMailer.with(user: user).trial_ended
  end

  def trial_reminder
    user = User.first
    FreeTrialMailer.with(user: user).trial_reminder
  end
end
