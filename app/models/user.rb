class User < ApplicationRecord
  include Discard::Model
  include Followable, Subscribable

  before_validation :downcase_email

  has_one :blog, dependent: :destroy, inverse_of: :user
  has_many :access_requests, dependent: :destroy

  accepts_nested_attributes_for :blog

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def verify!
    self.update! verified: true
  end

  private

    def downcase_email
      self.email = email.downcase.strip
    end
end
