module Draftable
  extend ActiveSupport::Concern

  included do
    enum :status, [ :draft, :published ] if table_exists? && column_names.include?("status")

    scope :draft, -> { where(status: :draft) }
    scope :published, -> { where(status: :published) }
  end

  def publish!
    update!(status: :published)
  end

  def unpublish!
    update!(status: :draft)
  end
end
