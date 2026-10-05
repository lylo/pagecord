class CancellationMailer < CloudflareMailer
  helper :routing

  default from: "Olly at Pagecord <hello@cfmail.pagecord.com>",
          reply_to: "Olly at Pagecord <olly@pagecord.com>"

  def subscriber_cancellation
    if (ends_at = params[:user].subscription&.next_billed_at)
      @ends_on = ends_at.strftime("%-d %B %Y")
      @domain_ends_on = (ends_at + Subscribable::CUSTOM_DOMAIN_GRACE_PERIOD.days).strftime("%-d %B %Y")
    end

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
