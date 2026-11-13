# Addresses that belong to bots rather than people. Add rules here as patterns
# show up; callers only ask whether an address is suspicious.
class SuspiciousEmail
  DOTTED_GMAIL_MINIMUM_DOTS = 3
  BLOCKED_DOMAINS = %w[ grokbot.com ].freeze

  def initialize(email)
    @email = email.to_s
  end

  def suspicious?
    dotted_gmail? || blocked_domain?
  end

  private

    def blocked_domain?
      domain = @email.split("@", 2)[1].to_s.downcase
      BLOCKED_DOMAINS.any? { |blocked| domain == blocked || domain.end_with?(".#{blocked}") }
    end

    # Gmail ignores dots in the local part, so one inbox can be reached through
    # endless variations of the same address.
    def dotted_gmail?
      local, domain = @email.split("@", 2)
      return false unless domain&.downcase == "gmail.com"

      local.to_s.count(".") >= DOTTED_GMAIL_MINIMUM_DOTS
    end
end
