class DeleteExpiredSenderEmailAddressesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Deleting expired, unaccepted sender email addresses"
    count = SenderEmailAddress.expired
                              .pending
                              .delete_all
    Rails.logger.info "Deleted #{count} expired sender email addresses"
  end
end
