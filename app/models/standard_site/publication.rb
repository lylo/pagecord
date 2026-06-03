class StandardSite::Publication < ApplicationRecord
  include Rails.application.routes.url_helpers
  include RoutingHelper

  self.table_name = "standard_site_publications"

  belongs_to :blog

  enum :sync_status, { pending: 0, synced: 1, failed: 2, disabled: 3 }

  validates :blog_id, uniqueness: true
  validates :rkey, presence: true
  validates :at_uri, format: { with: %r{\Aat://did:[^/]+/site\.standard\.publication/[^/]+\z} }, allow_blank: true

  def record
    {
      "$type" => StandardSite::COLLECTION_PUBLICATION,
      "url" => blog_home_url(blog).delete_suffix("/"),
      "name" => blog.display_name,
      "description" => description,
      "preferences" => {
        "showInDiscover" => blog.allow_search_indexing? && blog.user.search_indexable?
      }
    }.compact
  end

  def sync!
    update!(sync_status: :pending, sync_error: nil)

    result = StandardSite::Client.new(blog.standard_site_account).put_record(
      collection: StandardSite::COLLECTION_PUBLICATION,
      rkey: rkey,
      record: record
    )

    update!(
      at_uri: result.fetch("uri"),
      cid: result.fetch("cid"),
      sync_status: :synced,
      last_synced_at: Time.current,
      sync_error: nil
    )
  rescue StandardSite::Client::Error => e
    update!(sync_status: :failed, sync_error: e.message)
  end

  private

    def description
      if blog.bio.present?
        ActionView::Base.full_sanitizer.sanitize(blog.bio.to_s).squish.truncate(3000)
      else
        blog.display_name
      end
    end
end
