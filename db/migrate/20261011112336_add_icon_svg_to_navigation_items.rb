class AddIconSvgToNavigationItems < ActiveRecord::Migration[8.2]
  def change
    add_column :navigation_items, :icon_svg, :text
    add_column :navigation_items, :show_label, :boolean, default: true, null: false
  end
end
