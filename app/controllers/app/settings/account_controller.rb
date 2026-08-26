class App::Settings::AccountController < App::BaseController
  def edit
    @subscription = Current.user.subscription
    @blog = Current.blog
    @sender_email_address = SenderEmailAddress.new
  end
end
