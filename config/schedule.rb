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

every :day, at: "5:10 am" do
  runner "SendTrialReminderEmailsJob.perform_later"
end

every :day, at: "5:15 am" do
  runner "SendTrialEndedEmailsJob.perform_later"
end

# Spam blogs earn their keep from indexed backlinks, so the sooner they are
# flagged the less they get out of us. Cheap to run: blogs with a detection drop
# out, and empty ones are skipped before the model is called.
every 3.hours do
  runner "SpamDetectionJob.perform_later"
end

every :day, at: "7:00 am" do
  runner "SpamDetectionDigestJob.perform_later"
end

# Once a day, deliberately: a moderation queue shouldn't nag. The interval must
# match CommentDigestJob::WINDOW.
every :day, at: "7:30 am" do
  runner "CommentDigestJob.perform_later"
end

every 1.hour do
  runner "ContentModerationBatchJob.perform_later"
end

every :day, at: "8:00 am" do
  runner "ContentModerationDigestJob.perform_later"
end

# Digests go out on Tuesdays, so sweep Postmark the morning after while the bounces are fresh.
every :wednesday, at: "8:15 am" do
  runner "DeliverabilityDigestJob.perform_later"
end

every :day, at: "3:30 am" do
  runner "Posts::EmptyTrashJob.perform_later"
end

every :day, at: "3:35 am" do
  runner "Blogs::EmptyTrashJob.perform_later"
end

every :day, at: "3:40 am" do
  runner "Blogs::ClearLapsedCustomDomainsJob.perform_later"
end

every 1.month, at: "1:30 am" do  # 1:30 AM on the 1st of every month
  runner "RollupAndCleanupPageViewsJob.perform_later"
end

every 1.month, at: "2:00 am" do
  runner "SendUnengagedFollowUpEmailsJob.perform_later"
end

# every hour on a Tuesday
every "0 * * * 2" do
  rake "post_digests:deliver"
end

# Independent off-Ubicloud DB backup to R2 (bin/backup-db). Weekly is plenty on top
# of Ubicloud's managed 7-day PITR; switch to `every :day` for more restore points.
every :sunday, at: "4:20 am" do
  rake "db:backup"
end

# Refresh the DB-IP country database (no longer tracked in git). DB-IP publishes
# a new dated file each month; GeoIp.lookup returns nil until the file exists.
every "15 4 3 * *" do
  rake "geoip:update"
end
