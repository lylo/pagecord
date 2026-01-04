# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# Run hourly instead of suggested 5 min to reduce overhead
every 1.hour do
  rake "pghero:capture_query_stats"
end

every 1.day, at: "1:00 am" do
  rake "pghero:capture_space_stats"
  runner "PgHero.clean_query_stats(before: 7.days.ago)"  # Reduced from default of 14 to save space
  runner "PgHero.clean_space_stats(before: 90.days.ago)"
end

every 1.day, at: "2:30 am" do
  rake "email_change_requests:cleanup"
end

every 1.day, at: "2:35 am" do
  rake "sender_email_addresses:cleanup"
end

every 1.day, at: "2:40 am" do
  rake "access_requests:cleanup"
end

every 1.week, at: "3:00 am" do
  rake "email_subscribers:cleanup_unconfirmed"
end

every :day, at: "4:00 am" do
  rake "exports:cleanup"
end

every 1.day, at: "4:30 am" do
  rake "accounts:purge_cancellations"
end

every :day, at: "5:00 am" do
  rake "subscriptions:send_renewal_reminders"
end

every :day, at: "5:30 am" do
  runner "SpamDetectorJob.perform_later"
end

every 1.week, at: "6:00 am" do
  rake "posts:clear_old_raw_content"
end

every 1.month, at: "1:30 am" do  # 1:30 AM on the 1st of every month
  runner "RollupAndCleanupPageViewsJob.perform_later"
end

# every hour on a Tuesday
every "0 * * * 2" do
  rake "post_digests:deliver"
end
