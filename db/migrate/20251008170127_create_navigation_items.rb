class CreateNavigationItems < ActiveRecord::Migration[8.1]
  def change
    create_table :navigation_items do |t|
      t.references :blog, null: false, foreign_key: true
      t.references :post, null: true, foreign_key: true
      t.string :type, null: false
      t.string :label
      t.string :url
      t.string :platform
      t.integer :position, default: 0, null: false
      t.timestamps
    end

    add_index :navigation_items, [ :blog_id, :position ]
    add_index :navigation_items, :type
  end
end
