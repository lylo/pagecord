class AddLocaleToBlog < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :locale, :string, default: 'en', null: false
  end
end
