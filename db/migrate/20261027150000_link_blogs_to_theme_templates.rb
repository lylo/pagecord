class LinkBlogsToThemeTemplates < ActiveRecord::Migration[8.2]
  STYLESHEETS = Rails.root.join("app/assets/stylesheets/themes")

  def up
    add_column :theme_templates, :slug, :string
    add_column :theme_templates, :version, :integer, default: 1, null: false
    execute "UPDATE theme_templates SET slug = trim(both '-' from lower(regexp_replace(name, '[^a-zA-Z0-9]+', '-', 'g')))"
    change_column_null :theme_templates, :slug, false
    change_column_null :theme_templates, :custom_css, true
    add_index :theme_templates, :slug, unique: true

    add_reference :blogs, :theme_template, foreign_key: true
    add_column :blogs, :theme_template_version, :integer

    verify_stylesheets
  end

  def down
    remove_column :blogs, :theme_template_version
    remove_reference :blogs, :theme_template
    remove_index :theme_templates, :slug
    change_column_null :theme_templates, :custom_css, false
    remove_column :theme_templates, :slug
    remove_column :theme_templates, :version
  end

  private

    # Every template's stylesheet must be the CSS production holds, byte for byte
    # once line endings and outer whitespace are set aside, before anything links to it
    def verify_stylesheets
      mismatches = select_rows("SELECT name, slug, custom_css FROM theme_templates").filter_map do |name, slug, css|
        path = STYLESHEETS.join("#{slug}.css")

        if !path.exist?
          "#{name}: no app/assets/stylesheets/themes/#{slug}.css"
        elsif normalize(path.read) != normalize(css)
          "#{name}: themes/#{slug}.css differs from the database"
        end
      end

      return if mismatches.empty?

      raise "Theme stylesheets don't match the database:\n#{mismatches.join("\n")}" if Rails.env.production?

      say "Theme stylesheets don't match this database, which only matters in production:\n#{mismatches.join("\n")}"
    end

    def normalize(css)
      css.to_s.gsub("\r\n", "\n").strip
    end
end
