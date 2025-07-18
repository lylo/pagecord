class WelcomeMailerPreview < ActionMailer::Preview
  def welcome_email
    @user = User.first
    @blog = @user.blog
    WelcomeMailer.with(user: @user, blog: @blog, price: "29").welcome_email
  end
end
