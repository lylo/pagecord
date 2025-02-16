class CreateBlogExports < ActiveRecord::Migration[8.1]
  def change
    create_table :blog_exports do |t|
      t.references :blog, null: false, foreign_key: true
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
