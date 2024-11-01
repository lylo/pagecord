class AddTokenToPost < ActiveRecord::Migration[8.0]
  # this is how we used to generate a unique token for each post :(
  OFFSET = 100_000_000.freeze
  def opaque_id(id)
    (id + OFFSET).to_s(16)
  end

  def change
    add_column :posts, :token, :string

    # existing posts should use the old opaque id
    Post.find_each do |post|
      post.update token: opaque_id(post.id)
    end

    change_column :posts, :token, :string, null: false
  end
end
