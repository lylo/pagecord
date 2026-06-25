namespace :subscriptions do
  desc "Send renewal reminders to subscribers"
  task send_renewal_reminders: :environment do
    Subscription::SendRenewalRemindersJob.perform_now
  end

  desc "Reconcile Pagecord subscriptions against Paddle Billing"
  task reconcile_paddle: :environment do
    PaddleSubscriptionReconciliation.new.run
  end
end
