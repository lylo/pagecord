class FreeTrialMailerPreview < ActionMailer::Preview
  def trial_ended
    user = User.first
    FreeTrialMailer.with(user: user).trial_ended
  end
end
