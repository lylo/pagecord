class EmailSubscriber < ApplicationRecord
  include Tokenable

  belongs_to :blog

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }

  def confirmed?
    confirmed_at.present?
  end

  def unconfirmed?
    !confirmed?
  end

  def confirm!
    update!(confirmed_at: Time.current) unless confirmed?
  end
end
