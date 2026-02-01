class Blogs::ContactMessagesController < Blogs::BaseController
  include SpamPrevention

  skip_before_action :authenticate, :ip_reputation_check

  def create
    unless @blog.contactable?
      head :unprocessable_entity
      return
    end

    @contact_message = @blog.contact_messages.new(contact_message_params)

    if @contact_message.save
      SendContactMessageJob.perform_later(@contact_message.id)
      redirect_to blog_posts_path, notice: I18n.t("contact_form.success_message")
    else
      redirect_to blog_posts_path, alert: I18n.t("contact_form.error_message")
    end
  end

  private

    def contact_message_params
      params.require(:contact_message).permit(:name, :email, :message)
    end
end
