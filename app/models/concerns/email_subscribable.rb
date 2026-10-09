module EmailSubscribable
  extend ActiveSupport::Concern

  included do
    has_many :email_subscribers, dependent: :destroy
    has_many :post_digests, dependent: :destroy

    enum :email_delivery_mode, { digest: 0, individual: 1 }
  end

  DAILY_UNCONFIRMED_SUBSCRIBER_LIMIT = 5

  def recent_unconfirmed_subscribers_count
    email_subscribers.unconfirmed.where(created_at: 1.day.ago..).count
  end
end
