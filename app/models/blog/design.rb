module Blog::Design
  extend ActiveSupport::Concern

  included do
    belongs_to :theme_template, optional: true
  end

  def apply_design(template)
    assign_attributes(template.appearance_attributes)
    self.custom_css = nil if ThemeTemplate.copied_css?(custom_css)
    save
  end

  def design_stylesheet
    theme_template&.stylesheet(theme_template_version)
  end
end
