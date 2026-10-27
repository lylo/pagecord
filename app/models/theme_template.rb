class ThemeTemplate < ApplicationRecord
  include Themeable

  STYLESHEETS = Rails.root.join("app/assets/stylesheets/themes")

  self.ignored_columns += [ "custom_css" ]

  enum :layout, [ :stream_layout, :title_layout, :cards_layout ]

  has_many :blogs, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/ }
  validates :version, numericality: { only_integer: true, greater_than: 0 }
  validate :stylesheet_exists

  attr_readonly :slug

  before_validation :clear_custom_theme_colors, unless: :custom_theme?
  before_validation { self.slug = name.to_s.parameterize if slug.blank? }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :id) }
  scope :offered_to, ->(blog) { active.or(where(id: blog.theme_template_id)) }

  # A blog with an untouched copy of a template's CSS in custom_css, from before
  # designs were linked
  def self.copied_css?(css)
    css.present? && all.any? { |template| template.stylesheet_versions.any? { normalize_css(template.css(it)) == normalize_css(css) } }
  end

  def self.normalize_css(css)
    css.to_s.gsub("\r\n", "\n").strip
  end

  def stylesheet(version = self.version)
    version == 1 ? "themes/#{slug}" : "themes/#{slug}-#{version}"
  end

  def stylesheet?(version = self.version)
    stylesheet_path(version).exist?
  end

  def css(version = self.version)
    stylesheet_path(version).read
  end

  def stylesheet_versions
    (1..version).select { stylesheet?(it) }
  end

  def screenshot_asset
    "theme_templates/#{slug}.webp"
  end

  def screenshot?
    slug.present? && Rails.root.join("app/assets/images", screenshot_asset).exist?
  end

  def appearance_attributes
    {
      theme_template_id: id,
      theme_template_version: version,
      theme: theme.presence,
      font: font.presence,
      width: width.presence,
      layout: layout.presence,
      **(theme == "custom" ? {
        custom_theme_bg_light:, custom_theme_text_light:, custom_theme_accent_light:,
        custom_theme_bg_dark:, custom_theme_text_dark:, custom_theme_accent_dark:
      } : {})
    }.compact_blank
  end

  private

    def clear_custom_theme_colors
      assign_attributes(
        custom_theme_bg_light: nil, custom_theme_text_light: nil, custom_theme_accent_light: nil,
        custom_theme_bg_dark: nil,  custom_theme_text_dark: nil,  custom_theme_accent_dark: nil
      )
    end

    def stylesheet_path(version)
      STYLESHEETS.join("#{stylesheet(version).delete_prefix("themes/")}.css")
    end

    def stylesheet_exists
      return if slug.blank? || version.blank?

      errors.add(:version, "has no stylesheet at app/assets/stylesheets/#{stylesheet}.css") unless stylesheet?
    end
end
