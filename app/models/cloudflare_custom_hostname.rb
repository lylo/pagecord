class CloudflareCustomHostname < ApplicationRecord
  belongs_to :blog

  validates :domain, presence: true, uniqueness: true
  validates :external_id, presence: true, uniqueness: true
end
