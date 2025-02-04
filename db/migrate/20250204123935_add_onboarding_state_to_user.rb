class AddOnboardingStateToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :onboarding_state, :string, default: "account_created"
  end
end
