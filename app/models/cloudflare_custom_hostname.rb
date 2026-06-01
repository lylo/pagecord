class CloudflareCustomHostname < ApplicationRecord
  belongs_to :blog

  validates :domain, presence: true, uniqueness: true
  validates :external_id, presence: true, uniqueness: true

  before_validation :normalize_domain

  private

    def normalize_domain
      self.domain = domain.to_s.strip.downcase.presence
    end
end
