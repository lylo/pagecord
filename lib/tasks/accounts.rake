namespace :accounts do
  desc "Expire the cache for the home page"
  task purge_cancellations: :environment do
    discard_date = 7.days.ago
    users = User.purgeable_discarded(before: discard_date)

    Rails.logger.info "Purging #{users.count} accounts cancelled prior to #{discard_date.to_formatted_s(:short)}"
    users.destroy_all
  end
end
