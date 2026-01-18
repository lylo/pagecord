module Subscribable
  extend ActiveSupport::Concern

  TRIAL_PERIOD_DAYS = 14

  included do
    has_one :subscription, dependent: :destroy
    has_many :paddle_events, dependent: :destroy

    before_create :set_trial_ends_at
  end

  def subscribed?
    subscription&.active?
  end

  def on_trial?
    trial_ends_at.present? && trial_ends_at >= Date.current && !subscribed?
  end

  def has_premium_access?
    subscribed? || on_trial?
  end

  def trial_days_remaining
    return 0 unless on_trial?
    (trial_ends_at - Date.current).to_i
  end

  def on_free_plan?
    !subscribed? && !on_trial?
  end

  def lapsed?
    subscription&.lapsed?
  end

  private

    def set_trial_ends_at
      self.trial_ends_at ||= Date.current + TRIAL_PERIOD_DAYS.days
    end
end
