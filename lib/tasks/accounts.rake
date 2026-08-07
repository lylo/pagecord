namespace :accounts do
  desc "Expire the cache for the home page"
  task purge_cancellations: :environment do
    discard_date = 7.days.ago
    users = User.purgeable_discarded(before: discard_date)

    Rails.logger.info "Purging #{users.count} accounts cancelled prior to #{discard_date.to_formatted_s(:short)}"

    # Last moment this data exists, so record the departure before it goes. Restored
    # accounts never reach here, and a failed DestroyUserJob doesn't lose the record.
    users.find_each { |user| Churn.record(user, :account_deleted, occurred_at: user.discarded_at) }

    users.destroy_all
  end
end
