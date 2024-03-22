class Post < ApplicationRecord
  belongs_to :user

  before_create :set_published_at

  def url_title
    title.parameterize.truncate(100)
  end

  def url_id
    id.to_s(36)
  end

  private

    def set_published_at
      self.published_at ||= created_at
    end
end
