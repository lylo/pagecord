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
every :day, at: "4:00 am" do
  rake "exports:cleanup"
end

every 1.day, at: "4:30 am" do
  rake "accounts:purge_cancellations"
end

every :day, at: "5:00 am" do
  rake "subscriptions:send_renewal_reminders"
end

every 1.day, at: "8 am" do
  rake "marketing_automation:getting_started"
end

every :tuesday, at: "9 am" do
  rake "post_digests:deliver"
end
