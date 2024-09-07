class AddFreeTrialEndsAt < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :free_trial_ends_at, :datetime

    User.find_each do |user|
      user.update! free_trial_ends_at: user.created_at + 7.days
    end
  end
end
