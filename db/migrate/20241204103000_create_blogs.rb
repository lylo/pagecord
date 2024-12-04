class CreateBlogs < ActiveRecord::Migration[8.1]
  def change
    create_table :blogs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :delivery_email
      t.datetime :discarded_at
      t.string :custom_domain
      t.string :title

      t.timestamps
    end

    # create blog for each existing user
    User.find_each do |user|
      Blog.create!(user: user, delivery_email: user.delivery_email, custom_domain: user.custom_domain, title: user.title)
    end
  end
end
