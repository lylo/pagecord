class DropSocialLinks < ActiveRecord::Migration[8.1]
  def change
    drop_table :social_links do |t|
      t.references :blog, null: false, foreign_key: true
      t.string :platform
      t.string :url

      t.timestamps
    end
  end
end
