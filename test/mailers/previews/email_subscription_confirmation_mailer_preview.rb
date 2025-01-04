class EmailSubscriptionConfirmationMailerPreview < ActionMailer::Preview
  def confirm
    EmailSubscriptionConfirmationMailer.with(subscriber: EmailSubscriber.first).confirm
  end
end
