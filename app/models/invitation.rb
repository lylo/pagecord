class Invitation < ApplicationRecord
  CODE_LENGTH = 10
  CODE_CHARACTERS = [ *"A".."Z", *"2".."9" ] - %w[ I O ]

  belongs_to :inviter, class_name: "User"
  belongs_to :invitee, class_name: "User", optional: true

  scope :available, -> { where(redeemed_at: nil, inviter: User.kept) }

  normalizes :code, with: -> { it.strip.upcase }

  before_validation -> { self.code ||= SecureRandom.alphanumeric(CODE_LENGTH, chars: CODE_CHARACTERS) }, on: :create
  before_save -> { self.redeemed_at ||= Time.current }, if: :invitee

  def self.required?
    ENV["INVITE_ONLY"].present?
  end
end
