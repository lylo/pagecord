namespace :sender_email_addresses do
  desc "Deletes expired, unverified sender email addresses (older than 1 day)"
  task cleanup: :environment do
    DeleteExpiredSenderEmailAddressesJob.perform_later
  end
end