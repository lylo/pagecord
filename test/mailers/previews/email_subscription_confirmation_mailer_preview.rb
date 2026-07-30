class EmailSubscriptionConfirmationMailerPreview < ActionMailer::Preview
  def confirm
    subscriber = EmailSubscriber.first
    subscriber.blog.locale = params[:locale] if params[:locale]

    EmailSubscriptionConfirmationMailer.with(subscriber: subscriber).confirm
  end
end
