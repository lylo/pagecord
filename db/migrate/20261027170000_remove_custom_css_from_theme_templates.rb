class RemoveCustomCssFromThemeTemplates < ActiveRecord::Migration[8.2]
  def change
    remove_column :theme_templates, :custom_css, :text
  end
end
