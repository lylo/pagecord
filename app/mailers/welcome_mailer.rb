class WelcomeMailer < ApplicationMailer
  helper :routing

 default from: "Olly at Pagecord <hello@mailer.pagecord.com>",
         reply_to: "Olly at Pagecord <olly@pagecord.com>"

  def welcome_email
    @user = params[:user]
    @blog = @user.blog
    @price = params[:price] || Subscription.price

    mail to: @user.email, subject: "Welcome to Pagecord!"
  end

  def unengaged_follow_up
    @user = params[:user]
    @blog = @user.blog

    mail to: @user.email, subject: "Can I help you get started with Pagecord?"
  end
end
