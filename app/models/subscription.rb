class Subscription < ApplicationRecord
  belongs_to :user

  def cancelled?
    cancelled_at.present?
  end

  def lapsed?
    next_billed_at < Time.current
  end
end
