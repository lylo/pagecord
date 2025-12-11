class CancellationMailer < MailpaceMailer
  helper :routing

  default from: "Olly at Pagecord <hello@mailer.pagecord.com>",
          reply_to: "Olly at Pagecord <olly@pagecord.com>"

  def subscriber_cancellation
    send_email
  end

  def free_account_cancellation
    send_email
  end

  private

    def send_email
      @user = params[:user]
      @blog = @user.blog

      mail to: @user.email, subject: "Pagecord - sorry to see you go"
    end
end
