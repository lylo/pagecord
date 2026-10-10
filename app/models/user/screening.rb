class User::Screening < ApplicationRecord
  belongs_to :user

  scope :failed, -> { where.not(failed_checks: {}) }

  def failed?
    failed_checks.any?
  end
end
