class RollupAndCleanupPageViewsJob < ApplicationJob
  queue_as :default
  
  def perform
    # Rollup data older than 7 days, then delete raw records
    cutoff_date = 7.days.ago
    old_data = PageView.where("viewed_at < ?", cutoff_date)
    
    # Perform rollups for old data - total views
    old_data.rollup("Total Views")
    old_data.group(:blog_id).rollup("Total Views by Blog") 
    old_data.group(:blog_id, :post_id).rollup("Total Views by Blog and Post")
    old_data.group(:blog_id, :country).rollup("Total Views by Blog and Country")
    
    # Perform rollups for old data - unique views only
    unique_old_data = old_data.where(is_unique: true)
    unique_old_data.rollup("Unique Views")
    unique_old_data.group(:blog_id).rollup("Unique Views by Blog")
    unique_old_data.group(:blog_id, :post_id).rollup("Unique Views by Blog and Post") 
    unique_old_data.group(:blog_id, :country).rollup("Unique Views by Blog and Country")
    
    # Delete raw data older than 7 days (now that it's rolled up)
    deleted_count = old_data.delete_all
    
    Rails.logger.info "Rolled up and deleted #{deleted_count} page views older than #{cutoff_date.to_date}"
    
    deleted_count
  end
end