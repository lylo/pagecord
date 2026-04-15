class ThemeTemplate < ApplicationRecord
  include CssSanitizable

  enum :layout, [ :stream_layout, :title_layout, :cards_layout ]

  validates :name, presence: true, uniqueness: true
  validates :custom_css, presence: true
  validates :theme, inclusion: { in: Themeable::THEMES }, allow_blank: true
  validates :font, inclusion: { in: Themeable::FONTS }, allow_blank: true
  validates :width, inclusion: { in: Themeable::PAGE_WIDTHS }, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, name: :asc) }

  def custom_theme_colors
    {
      light: {
        bg: custom_theme_bg_light.presence || "#ffffff",
        text: custom_theme_text_light.presence || "#334155",
        accent: custom_theme_accent_light.presence || "#334155"
      },
      dark: {
        bg: custom_theme_bg_dark.presence || "#0f172a",
        text: custom_theme_text_dark.presence || "#cbd5e1",
        accent: custom_theme_accent_dark.presence || "#ffffff"
      }
    }
  end

  def screenshot_asset
    "theme_templates/#{name.parameterize}.webp"
  end

  def screenshot?
    name.present? && Rails.root.join("app/assets/images", screenshot_asset).exist?
  end

  def reorder(new_position)
    transaction do
      old_position = position
      update_column(:position, -1)

      if new_position > old_position
        ThemeTemplate.where("position > ? AND position <= ?", old_position, new_position)
                     .update_all("position = position - 1")
      elsif new_position < old_position
        ThemeTemplate.where("position >= ? AND position < ?", new_position, old_position)
                     .update_all("position = position + 1")
      end

      update_column(:position, new_position)
    end
  end

  def appearance_attributes
    {
      custom_css:,
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
end
