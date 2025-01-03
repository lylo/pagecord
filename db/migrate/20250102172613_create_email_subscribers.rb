class CreateEmailSubscribers < ActiveRecord::Migration[8.1]
  def change
    create_table :email_subscribers do |t|
      t.references :blog, null: false, foreign_key: true
      t.string :email, null: false
      t.timestamps

      t.index %i[blog_id email], unique: true
    end
  end
end
