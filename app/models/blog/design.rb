module Blog::Design
  extend ActiveSupport::Concern

  IMPORT = /@import\s[^;]+;\s*/
  CUSTOM_COLOURS = Themeable::ATTRIBUTES.map(&:to_s).grep(/\Acustom_theme_/)

  included do
    belongs_to :theme_template, optional: true
  end

  class_methods do
    # No template is the classic design: the blog's own settings on blogs.css alone
    def classic_design_attributes
      column_defaults.slice("theme_template_id", "theme_template_version", "theme", "font", "width", "layout")
    end
  end

  # Custom colours go with the design that set them; colours the owner chose stay
  def assign_design(template)
    attributes = Blog.classic_design_attributes
    attributes.merge!(Blog.column_defaults.slice(*CUSTOM_COLOURS)) if theme_template && slice(*CUSTOM_COLOURS) == theme_template.slice(*CUSTOM_COLOURS)

    assign_attributes(attributes.merge(template&.appearance_attributes.to_h))
    self.custom_css = nil if ThemeTemplate.copied_css?(custom_css)
  end

  def apply_design(template)
    assign_design(template)
    save
  end

  # Back to the classic design with the stylesheet's CSS as the blog's own, to edit.
  # @import only works ahead of every other rule, so both parts' imports go first.
  def detach_design
    parts = [ theme_template.css(theme_template_version), custom_css.to_s ]
    imports = parts.flat_map { it.scan(IMPORT) }.map(&:strip).uniq
    rules = parts.map { it.gsub(IMPORT, "").strip }.compact_blank

    update(custom_css: [ imports.join("\n").presence, *rules ].compact.join("\n\n"), theme_template_id: nil, theme_template_version: nil)
  end

  # A design whose stylesheet is missing falls back to the classic design rather
  # than failing every page of the blog
  def design_stylesheet
    return unless theme_template

    if theme_template.stylesheet?(theme_template_version)
      theme_template.stylesheet(theme_template_version)
    else
      Rails.error.report(RuntimeError.new("Missing design stylesheet #{theme_template.stylesheet(theme_template_version)} for blog #{id}"))
      nil
    end
  end
end
