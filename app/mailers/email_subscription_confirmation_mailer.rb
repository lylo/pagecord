class EmailSubscriptionConfirmationMailer < ApplicationMailer
  def confirm
    @subscriber = params[:subscriber]

    mail(to: @subscriber.email, subject: "Confirm your subscription to #{@subscriber.blog.display_name}")
  end
end
