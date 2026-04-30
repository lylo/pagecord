class CreateThemeTemplates < ActiveRecord::Migration[8.2]
  def change
    create_table :theme_templates do |t|
      t.string :name, null: false
      t.text :description
      t.text :custom_css, null: false
      t.string :theme
      t.string :font
      t.string :width
      t.integer :layout
      t.string :custom_theme_bg_light
      t.string :custom_theme_text_light
      t.string :custom_theme_accent_light
      t.string :custom_theme_bg_dark
      t.string :custom_theme_text_dark
      t.string :custom_theme_accent_dark
      t.string :author_name
      t.string :author_url
      t.integer :position, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :theme_templates, :active
    add_index :theme_templates, :position
  end
end
