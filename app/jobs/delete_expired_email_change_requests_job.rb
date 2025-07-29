class DeleteExpiredEmailChangeRequestsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Deleting expired, non-accepted email change requests"
    count = EmailChangeRequest.where("expires_at < ?", Time.current)
                              .where(accepted_at: nil)
                              .delete_all
    Rails.logger.info "Deleted #{count} expired email change requests"
  end
end
