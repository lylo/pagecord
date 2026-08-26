class Admin::ThemeTemplates::FixturesController < Admin::BaseController
  def index
    fixtures = ThemeTemplate.ordered.each_with_object({}) do |template, hash|
      attributes = template.attributes.except("id", "created_at", "updated_at")
      attributes.compact_blank!
      hash[template.name.parameterize(separator: "_")] = attributes
    end

    send_data fixtures.to_yaml, filename: "theme_templates.yml", type: "text/yaml"
  end
end
