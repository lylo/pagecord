class Post < ApplicationRecord
  belongs_to :user

  before_create :set_published_at

  private

    def set_published_at
      self.published_at = created_at if self.published_at.nil?
    end
end
