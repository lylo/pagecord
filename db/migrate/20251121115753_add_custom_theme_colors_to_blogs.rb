class AddCustomThemeColorsToBlogs < ActiveRecord::Migration[8.2]
  def change
    add_column :blogs, :custom_theme_bg_light, :string
    add_column :blogs, :custom_theme_text_light, :string
    add_column :blogs, :custom_theme_accent_light, :string
    add_column :blogs, :custom_theme_bg_dark, :string
    add_column :blogs, :custom_theme_text_dark, :string
    add_column :blogs, :custom_theme_accent_dark, :string
  end
end
