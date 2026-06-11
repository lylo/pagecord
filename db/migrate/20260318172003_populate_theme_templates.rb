class PopulateThemeTemplates < ActiveRecord::Migration[8.2]
  def up
    return if ThemeTemplate.exists?

    fixtures = YAML.load_file(Rails.root.join("test/fixtures/theme_templates.yml"))

    fixtures.each do |_key, attrs|
      ThemeTemplate.create!(attrs)
    end
  end

  def down
    ThemeTemplate.destroy_all
  end
end
