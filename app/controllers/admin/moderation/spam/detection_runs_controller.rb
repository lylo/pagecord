class Admin::Moderation::Spam::DetectionRunsController < Admin::BaseController
  def create
    SpamDetectionJob.perform_later

    redirect_to admin_moderation_spam_index_path, notice: "Spam detection job queued"
  end
end
