namespace :subscriptions do
  desc "Send renewal reminders to subscribers"
  task send_renewal_reminders: :environment do
    Subscription::SendRenewalRemindersJob.perform_now
  end
end
