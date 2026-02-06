class UnengagedFollowUp < ApplicationRecord
  belongs_to :user

  validates :sent_at, presence: true
  validates :user_id, uniqueness: true
end
