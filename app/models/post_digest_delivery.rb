class PostDigestDelivery < ApplicationRecord
  belongs_to :post_digest
  belongs_to :email_subscriber
  has_one :email_event, class_name: "Email::Event", dependent: :destroy

  validates :email_subscriber_id, uniqueness: { scope: :post_digest_id }
end
