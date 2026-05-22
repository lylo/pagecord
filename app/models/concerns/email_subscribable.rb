module EmailSubscribable
  extend ActiveSupport::Concern

  included do
    has_many :email_subscribers, dependent: :destroy
    has_many :post_digests, dependent: :destroy

    enum :email_delivery_mode, { digest: 0, individual: 1 }
  end
end
