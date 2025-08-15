namespace :access_requests do
  desc "Delete expired access requests"
  task cleanup: :environment do
    Rails.logger.info "Cleaning up old access requests"
    count = AccessRequest.where("expires_at < ?", Time.current).destroy_all.count
    Rails.logger.info "Deleted #{count} old access requests"
  end
end
