module EmailSubscribable
  extend ActiveSupport::Concern

  included do
    has_many :email_subscribers, dependent: :destroy
    has_many :post_digests, dependent: :destroy
  end
end
