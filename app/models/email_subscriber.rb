require "csv"

class EmailSubscriber < ApplicationRecord
  include Tokenable

  belongs_to :blog

  has_many :post_digest_deliveries, dependent: :destroy

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }

  def self.to_csv
    CSV.generate do |csv|
      csv << %w[ email confirmed_at country ]
      order(:created_at).each do |subscriber|
        csv << [ subscriber.email, subscriber.confirmed_at&.iso8601, subscriber.country ]
      end
    end
  end

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :blog_id, message: "is already subscribed to this blog" }

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
