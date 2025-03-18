class EmailSubscriber < ApplicationRecord
  include Tokenable

  belongs_to :blog

  has_many :post_digest_deliveries, dependent: :destroy

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

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
