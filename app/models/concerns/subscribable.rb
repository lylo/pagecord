module Subscribable
  extend ActiveSupport::Concern

  TRIAL_PERIOD_DAYS = 14

  included do
    has_one :subscription, dependent: :destroy
    has_many :paddle_events, dependent: :destroy
  end

  def subscribed?
    subscription&.active?
  end

  def on_trial?
    created_at > TRIAL_PERIOD_DAYS.days.ago && !subscribed?
  end

  def trial_days_remaining
    return 0 unless on_trial?
    ((created_at + TRIAL_PERIOD_DAYS.days - Time.current) / 1.day).ceil
  end

  def on_free_plan?
    !subscribed? && !on_trial?
  end

  def lapsed?
    subscription&.lapsed?
  end
end
