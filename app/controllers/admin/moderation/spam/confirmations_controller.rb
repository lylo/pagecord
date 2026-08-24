class Admin::Moderation::Spam::ConfirmationsController < Admin::BaseController
  def create
    spam_detection = SpamDetection.find(params[:spam_id])
    spam_detection.mark_as_reviewed!

    DestroyUserJob.perform_later(spam_detection.blog.user.id, spam: true)

    redirect_to admin_moderation_spam_index_path, notice: "Spam confirmed and user will be discarded"
  end
end
