class AddFailedChecksToAccountTombstones < ActiveRecord::Migration[8.2]
  def change
    add_column :account_tombstones, :failed_checks, :jsonb
  end
end
