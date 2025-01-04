class PostDigestDelivery < ApplicationRecord
  belongs_to :post_digest
  belongs_to :email_subscriber

  validates :email_subscriber_id, uniqueness: { scope: :post_digest_id }
end
