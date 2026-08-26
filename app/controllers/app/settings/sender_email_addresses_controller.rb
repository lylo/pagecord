class App::Settings::SenderEmailAddressesController < App::BaseController
  rate_limit to: 3, within: 1.hour, only: :create, by: -> { Current.user.id }

  def create
    @sender_email_address = @blog.sender_email_addresses.new(sender_email_address_params)
    if @sender_email_address.save
      send_verification_email(@sender_email_address)

      redirect_to edit_app_settings_account_path, notice: "Verification email has been sent to #{@sender_email_address.email}."
    else
      redirect_to edit_app_settings_account_path, alert: @sender_email_address.errors.full_messages.join(", ")
    end
  end

  def destroy
    @sender_email_address = @blog.sender_email_addresses.find(params[:id])
    @sender_email_address&.destroy

    redirect_to edit_app_settings_account_path, notice: "Sender email address has been removed."
  end

  private

    def sender_email_address_params
      params.require(:sender_email_address).permit(:email)
    end

    def send_verification_email(sender_email_address)
      SenderEmailAddressMailer.with(sender_email_address: sender_email_address).verify.deliver_later
    end
end
