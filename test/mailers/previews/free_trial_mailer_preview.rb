class FreeTrialMailerPreview < ActionMailer::Preview
  def trial_ended
    user = User.first
    FreeTrialMailer.with(user: user).trial_ended
  end

  def trial_reminder
    user = User.first
    user.trial_ends_at ||= 3.days.from_now.to_date
    FreeTrialMailer.with(user: user).trial_reminder
  end
end
