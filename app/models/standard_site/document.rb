class StandardSite::Document < ApplicationRecord
  include Rails.application.routes.url_helpers
  include RoutingHelper

  self.table_name = "standard_site_documents"

  belongs_to :post

  enum :sync_status, { pending: 0, synced: 1, failed: 2, disabled: 3 }

  validates :post_id, uniqueness: true
  validates :rkey, presence: true
  validates :at_uri, format: { with: %r{\Aat://did:[^/]+/site\.standard\.document/[^/]+\z} }, allow_blank: true

  before_validation :set_rkey, on: :create

  def record
    publication = post.blog.standard_site_publication

    {
      "$type" => StandardSite::COLLECTION_DOCUMENT,
      "site" => publication.at_uri,
      "path" => post_path(post),
      "title" => post.display_title,
      "description" => post.summary(limit: 160),
      "textContent" => post.plain_text_content.truncate(30_000, omission: ""),
      "tags" => post.tag_list,
      "publishedAt" => post.published_at&.utc&.iso8601(3),
      "updatedAt" => post.updated_at.utc.iso8601(3)
    }.compact
  end

  def sync!
    return disable! unless syncable?

    update!(sync_status: :pending, sync_error: nil)

    result = StandardSite::Client.new(post.blog.standard_site_account).put_record(
      collection: StandardSite::COLLECTION_DOCUMENT,
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

  def disable!
    update!(sync_status: :disabled, sync_error: nil)
  end

  private

    def set_rkey
      self.rkey ||= post.token
    end

    def syncable?
      post.kept? &&
        post.published? &&
        !post.pending? &&
        !post.hidden? &&
        post.published_at.present? &&
        post.blog.standard_site_publication&.synced?
    end
end
