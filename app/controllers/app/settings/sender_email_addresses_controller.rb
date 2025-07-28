class App::Settings::SenderEmailAddressesController < AppController
  before_action :load_sender_email_address, only: [ :verify ]

  rate_limit to: 3, within: 1.hour, only: :create, by: -> { Current.user.id }

  def create
    @sender_email_address = @blog.sender_email_addresses.new(sender_email_address_params)
    if @sender_email_address.save
      send_verification_email(@sender_email_address)

      redirect_to app_settings_account_edit_path, notice: "Verification email has been sent to #{@sender_email_address.email}."
    else
      redirect_to app_settings_account_edit_path, alert: @sender_email_address.errors.full_messages.join(", ")
    end
  end

  def destroy
    @sender_email_address = @blog.sender_email_addresses.find(params[:id])
    @sender_email_address&.destroy

    redirect_to app_settings_account_edit_path, notice: "Sender email address has been removed."
  end

  def verify
    if @sender_email_address && !@sender_email_address.accepted? && !@sender_email_address.expired?
      @sender_email_address.accept!
      redirect_to app_settings_account_edit_path, notice: "Sender email address has been verified!"
    else
      redirect_to app_settings_account_edit_path, alert: "Invalid or expired verification link :("
    end
  end

  private

    def sender_email_address_params
      params.require(:sender_email_address).permit(:email)
    end

    def load_sender_email_address
      @sender_email_address = @blog.sender_email_addresses.find_by(token_digest: params[:token])
    end

    def send_verification_email(sender_email_address)
      SenderEmailAddressMailer.with(sender_email_address: sender_email_address).verify.deliver_later
    end
end
