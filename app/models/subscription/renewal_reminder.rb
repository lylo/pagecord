class Subscription::RenewalReminder < ApplicationRecord
  self.table_name = "subscription_renewal_reminders"

  belongs_to :subscription

  validates :period, presence: true
  validates :sent_at, presence: true
  validates :period, uniqueness: { scope: :subscription_id }

  def self.period_for(date)
    date.year.to_s
  end
end
