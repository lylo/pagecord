class FreeTrialMailer < ApplicationMailer
  def premium_only
    @user = params[:user]

    mail(to: @user.email, subject: "📣 Pagecord is now premium-only")
  end
end
