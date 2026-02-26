class AddTrialEndsAtToUsers < ActiveRecord::Migration[8.2]
  def change
    add_column :users, :trial_ends_at, :date
  end
end
