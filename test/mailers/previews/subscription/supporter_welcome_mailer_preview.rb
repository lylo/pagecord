class Subscription::SupporterWelcomeMailerPreview < ActionMailer::Preview
  def welcome
    subscription = Subscription.active_paid.first
    Subscription::SupporterWelcomeMailer.welcome(subscription)
  end
end
