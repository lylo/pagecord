class CreateBlogSpotlightExclusions < ActiveRecord::Migration[8.2]
  def change
    create_table :blog_spotlight_exclusions do |t|
      t.references :blog, null: false, foreign_key: true, index: { unique: true }
      t.timestamps
    end
  end
end
