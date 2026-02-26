class Email::Suppression < ApplicationRecord
  self.table_name = "email_suppressions"

  validates :email, presence: true
  validates :reason, presence: true, inclusion: { in: %w[bounce complaint] }
  validates :suppressed_at, presence: true

  scope :bounces, -> { where(reason: "bounce") }
  scope :complaints, -> { where(reason: "complaint") }

  def self.suppressed?(email)
    exists?(email: email.to_s.strip.downcase)
  end

  def self.suppress!(email, reason:, bounce_type: nil, diagnostic_code: nil)
    create_or_find_by!(email: email.to_s.strip.downcase) do |suppression|
      suppression.reason = reason
      suppression.bounce_type = bounce_type
      suppression.diagnostic_code = diagnostic_code
      suppression.suppressed_at = Time.current
    end
  end
end
