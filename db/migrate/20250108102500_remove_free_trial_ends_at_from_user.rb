class RemoveFreeTrialEndsAtFromUser < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :free_trial_ends_at
  end
end
