class WelcomeMailerPreview < ActionMailer::Preview
  def welcome_email
    @user = User.first
    @blog = @user.blog
    WelcomeMailer.with(user: @user, blog: @blog, price: "39").welcome_email
  end

  def onboarding_follow_up
    @user = User.find_by!(onboarding_state: "account_created")
    @blog = @user.blog
    WelcomeMailer.with(user: @user, blog: @blog).onboarding_follow_up
  end

  def no_content_follow_up
    @user = User.find_by!(email: "unengaged@example.com")
    @blog = @user.blog
    WelcomeMailer.with(user: @user, blog: @blog).no_content_follow_up
  end
end
