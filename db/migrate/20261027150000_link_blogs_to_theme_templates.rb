class LinkBlogsToThemeTemplates < ActiveRecord::Migration[8.2]
  def up
    add_column :theme_templates, :slug, :string
    add_column :theme_templates, :version, :integer, default: 1, null: false
    execute "UPDATE theme_templates SET slug = trim(both '-' from lower(regexp_replace(name, '[^a-zA-Z0-9]+', '-', 'g')))"
    change_column_null :theme_templates, :slug, false
    change_column_null :theme_templates, :custom_css, true
    add_index :theme_templates, :slug, unique: true

    add_reference :blogs, :theme_template, foreign_key: true
    add_column :blogs, :theme_template_version, :integer
  end

  def down
    remove_column :blogs, :theme_template_version
    remove_reference :blogs, :theme_template
    remove_index :theme_templates, :slug
    change_column_null :theme_templates, :custom_css, false
    remove_column :theme_templates, :slug
    remove_column :theme_templates, :version
  end
end
