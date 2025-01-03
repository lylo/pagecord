module EmailSubscribable
  extend ActiveSupport::Concern

  included do
    has_many :email_subscribers, dependent: :destroy
  end
end
