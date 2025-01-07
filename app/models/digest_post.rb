class DigestPost < ApplicationRecord
  belongs_to :post_digest
  belongs_to :post

  validates :post_id, uniqueness: { scope: :post_digest_id }
end
