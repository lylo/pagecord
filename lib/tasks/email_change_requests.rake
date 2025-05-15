namespace :email_change_requests do
  desc "Deletes expired email change requests"
  task cleanup: :environment do
    DeleteExpiredEmailChangeRequestsJob.perform_later
  end
end
