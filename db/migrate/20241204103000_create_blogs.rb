class CreateBlogs < ActiveRecord::Migration[8.1]
  def change
    create_table :blogs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :delivery_email
      t.string :name
      t.string :title
      t.string :custom_domain
      t.datetime :discarded_at

      t.timestamps
    end

    # create blog for each existing user
    User.find_each do |user|
      bio = ActionText::RichText.find_by(record_type: "User", record_id: user.id, name: "bio")

      Blog.create!(user: user,
        delivery_email: user.delivery_email,
        custom_domain: user.custom_domain,
        name: user.username,
        title: user.title,
        bio: bio
      )
    end

    remove_column :users, :username

    change_column_null :blogs, :name, false
    add_index :blogs, :name, unique: true
  end
end
