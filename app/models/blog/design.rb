module Blog::Design
  extend ActiveSupport::Concern

  included do
    belongs_to :theme_template, optional: true
  end

  class_methods do
    # No template is the classic design: the blog's own settings on blogs.css alone
    def classic_design_attributes
      column_defaults.slice("theme_template_id", "theme_template_version", *Themeable::ATTRIBUTES.map(&:to_s))
    end
  end

  def assign_design(template)
    assign_attributes(Blog.classic_design_attributes.merge(template&.appearance_attributes.to_h))
  end

  def apply_design(template)
    assign_design(template)
    self.custom_css = nil if ThemeTemplate.copied_css?(custom_css)
    save
  end

  # Back to the classic design with the stylesheet's CSS as the blog's own, to edit
  def detach_design
    css = theme_template.css(theme_template_version)
    update(custom_css: [ css, custom_css ].compact_blank.join("\n\n"), theme_template_id: nil, theme_template_version: nil)
  end

  def design_stylesheet
    theme_template&.stylesheet(theme_template_version)
  end
end
