namespace :email_subscribers do
  desc "Delete unconfirmed email subscribers older than 1 week"
  task cleanup_unconfirmed: :environment do
    unconfirmed = EmailSubscriber.unconfirmed.where("created_at < ?", 1.week.ago)
    count = unconfirmed.count

    if count > 0
      Rails.logger.info "Deleting #{count} unconfirmed email subscribers older than 1 week"
      unconfirmed.destroy_all
      Rails.logger.info "Successfully deleted #{count} unconfirmed email subscribers"
    else
      Rails.logger.info "No unconfirmed email subscribers to clean up"
    end
  end
end
