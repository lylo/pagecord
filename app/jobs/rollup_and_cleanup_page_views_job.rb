class RollupAndCleanupPageViewsJob < ApplicationJob
  queue_as :default

  def perform
    # Rollup data from previous months, then delete raw records
    cutoff_date = Date.current.beginning_of_month.beginning_of_day
    old_data = PageView.where("viewed_at < ?", cutoff_date)

    # === Total Views ===
    old_data.rollup("total_views")
    old_data.group(:blog_id).rollup("total_views_by_blog")
    old_data.group(:blog_id, :post_id).rollup("total_views_by_blog_post")

    # === Unique Views ===
    unique_old_data = old_data.where(is_unique: true)
    unique_old_data.rollup("unique_views")
    unique_old_data.group(:blog_id).rollup("unique_views_by_blog")
    unique_old_data.group(:blog_id, :post_id).rollup("unique_views_by_blog_post")

    deleted_count = old_data.delete_all
    Rails.logger.info "Rolled up and deleted #{deleted_count} page views older than #{cutoff_date.to_date}"

    deleted_count
  end
end
