class RollupAndCleanupPageViewsJob < ApplicationJob
  queue_as :default

  def perform
    # Rollup data older than 30 days, then delete raw records
    cutoff_date = 30.days.ago.beginning_of_day
    old_data = PageView.where("viewed_at < ?", cutoff_date)

    # === Total Views ===
    old_data.rollup("total_views")
    old_data.group(:blog_id).rollup("total_views_by_blog")
    old_data.group(:blog_id, :post_id).rollup("total_views_by_blog_post")
    old_data.group(:blog_id, :country).rollup("total_views_by_blog_country")

    # === Unique Views ===
    unique_old_data = old_data.where(is_unique: true)
    unique_old_data.rollup("unique_views")
    unique_old_data.group(:blog_id).rollup("unique_views_by_blog")
    unique_old_data.group(:blog_id, :post_id).rollup("unique_views_by_blog_post")
    unique_old_data.group(:blog_id, :country).rollup("unique_views_by_blog_country")

    deleted_count = old_data.delete_all
    Rails.logger.info "Rolled up and deleted #{deleted_count} page views older than #{cutoff_date.to_date}"

    deleted_count
  end
end
