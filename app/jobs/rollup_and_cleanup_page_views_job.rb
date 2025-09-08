class RollupAndCleanupPageViewsJob < ApplicationJob
  queue_as :default

  def perform
    # Always use previous month cutoff for rollup job (regardless of existing rollups)
    cutoff_date = Date.current.prev_month.beginning_of_month.beginning_of_day
    old_data = PageView.where("viewed_at < ?", cutoff_date)

    Rails.logger.info "RollupAndCleanupPageViewsJob starting with cutoff_date: #{cutoff_date}"

    if old_data.empty?
      Rails.logger.info "No page views found older than #{cutoff_date.to_date} - nothing to rollup"
      return 0
    end

    # === Unique Views ===
    Rails.logger.info "Creating unique view rollups..."
    unique_old_data = old_data.where(is_unique: true)
    unique_old_data.rollup("unique_views")
    unique_old_data.group(:blog_id).rollup("unique_views_by_blog")
    unique_old_data.group(:blog_id, :post_id).rollup("unique_views_by_blog_post")

    deleted_count = old_data.delete_all
    Rails.logger.info "Rolled up and deleted #{deleted_count} page views older than #{cutoff_date.to_date}"

    deleted_count
  end
end
