class AddShowBrandingFlagToBlog < ActiveRecord::Migration[8.1]
  def change
    add_column :blogs, :show_branding, :boolean, default: true, null: false
  end
end
