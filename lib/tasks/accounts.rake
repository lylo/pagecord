namespace :accounts do
  desc "Expire the cache for the home page"
  task purge_cancellations: :environment do
    discard_date = 7.days.ago
    users = User.purgeable_discarded(before: discard_date)

    Rails.logger.info "Purging #{users.count} accounts cancelled prior to #{discard_date.to_formatted_s(:short)}"
    users.destroy_all
  end

  desc "Delete accounts that were never verified, a week after signup"
  task purge_unverified: :environment do
    users = User.purgeable_unverified(before: 7.days.ago)

    Rails.logger.info "Purging #{users.count} unverified accounts"
    users.destroy_all
  end
end
