class WelcomeMailerPreview < ActionMailer::Preview
  def welcome_email
    WelcomeMailer.with(user: User.first).welcome_email
  end

  def onboarding_follow_up
    WelcomeMailer.with(user: User.find_by(onboarding_state: "account_created") || User.first).onboarding_follow_up
  end

  def no_content_follow_up
    WelcomeMailer.with(user: User.find_by(onboarding_state: "account_created") || User.first).no_content_follow_up
  end
end
