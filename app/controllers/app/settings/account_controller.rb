class App::Settings::AccountController < AppController
  def edit
    @subscription = Current.user.subscription
    @blog = Current.user.blog
    @sender_email_address = SenderEmailAddress.new
  end
end
