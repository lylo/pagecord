namespace :exports do
  desc "Delete exports older than 1 week"
  task cleanup: :environment do
    Rails.logger.info "Cleaning up old exports"
    count = Blog::Export.where("created_at < ?", 1.week.ago).destroy_all.count
    Rails.logger.info "Deleted #{count} old exports"
  end
end
