class AddKindToPostDigests < ActiveRecord::Migration[8.2]
  def change
    add_column :post_digests, :kind, :integer, default: 0, null: false
  end
end
