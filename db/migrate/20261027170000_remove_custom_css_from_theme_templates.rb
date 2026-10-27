class RemoveCustomCssFromThemeTemplates < ActiveRecord::Migration[8.2]
  STYLESHEETS = Rails.root.join("app/assets/stylesheets/themes")

  def up
    missing = select_values("SELECT slug FROM theme_templates").reject { STYLESHEETS.join("#{it}.css").exist? }
    raise "No stylesheet for #{missing.to_sentence}, so their CSS would be lost" if missing.any?

    remove_column :theme_templates, :custom_css
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
