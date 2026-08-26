class Admin::Moderation::Spam::DismissalsController < Admin::BaseController
  def create
    spam_detection = SpamDetection.find(params[:spam_id])
    spam_detection.update!(status: :clean, reviewed_at: Time.current)

    redirect_to admin_moderation_spam_index_path, notice: "Blog marked as clean"
  end
end
