module Onboardable
  extend ActiveSupport::Concern

  STATES = %w[account_created completed].freeze

  included do
    validates :onboarding_state, presence: true, inclusion: { in: STATES }

    def onboarding_complete?
      onboarding_state == "completed"
    end

    def onboarding_complete!
      update!(onboarding_state: "completed")
    end

    def account_created!
      update!(onboarding_state: "account_created")
    end
  end
end
