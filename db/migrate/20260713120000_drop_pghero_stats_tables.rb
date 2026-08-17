class DropPgheroStatsTables < ActiveRecord::Migration[8.2]
  def up
    drop_table :pghero_query_stats, if_exists: true
    drop_table :pghero_space_stats, if_exists: true
  end

  def down
    create_table :pghero_query_stats do |t|
      t.text :database
      t.text :user
      t.text :query
      t.bigint :query_hash
      t.float :total_time
      t.bigint :calls
      t.datetime :captured_at, precision: nil
    end
    add_index :pghero_query_stats, [ :database, :captured_at ]

    create_table :pghero_space_stats do |t|
      t.text :database
      t.text :schema
      t.text :relation
      t.bigint :size
      t.datetime :captured_at, precision: nil
    end
    add_index :pghero_space_stats, [ :database, :captured_at ]
  end
end
