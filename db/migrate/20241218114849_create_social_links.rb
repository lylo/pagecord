class CreateSocialLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :social_links do |t|
      t.references :blog, null: false, foreign_key: true
      t.string :platform, null: false
      t.string :url, null: false

      t.timestamps
    end
  end
end
