class Email::Event < ApplicationRecord
  self.table_name = "email_events"

  belongs_to :post_digest_delivery

  validates :message_id, presence: true
  validates :provider, presence: true, inclusion: { in: %w[ses postmark] }
  validates :status, inclusion: { in: %w[sent delivered bounced complained] }
end
