module Subscribable
  extend ActiveSupport::Concern

  included do
    has_one :subscription, dependent: :destroy
    has_many :paddle_events, dependent: :destroy
  end

  def subscribed?
    subscription&.active?
  end

  def lapsed?
    subscription&.lapsed?
  end
end
