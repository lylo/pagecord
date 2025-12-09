module Themeable
  extend ActiveSupport::Concern

  class ColorFormatValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      if value.present? && !value.match?(/\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/)
        record.errors.add(attribute, "must be a valid hex color code (e.g., #RRGGBB)")
      end
    end
  end

  THEMES = %w[base mint lavender coral sand sky berry custom].freeze
  FONTS = %w[sans serif mono].freeze
  PAGE_WIDTHS = %w[narrow standard wide].freeze

  included do
    validates :theme, inclusion: { in: THEMES, message: "%{value} is not a valid theme" }
    validates :font, inclusion: { in: FONTS, message: "%{value} is not a valid font" }
    validates :width, inclusion: { in: PAGE_WIDTHS, message: "%{value} is not a valid width" }

    validates :custom_theme_bg_light, :custom_theme_text_light, :custom_theme_accent_light,
              :custom_theme_bg_dark, :custom_theme_text_dark, :custom_theme_accent_dark,
              color_format: true, if: :custom_theme?
  end

  def serif?
    font == "serif"
  end

  def sans_serif?
    font == "sans-serif"
  end

  def mono?
    font == "mono"
  end

  def font_class
    case font
    when "serif"
      "font-serif"
    when "mono"
      "font-mono"
    else
      "font-sans"
    end
  end

  def narrow?
    width == "narrow"
  end

  def standard?
    width == "standard"
  end

  def wide?
    width == "wide"
  end

  def custom_theme?
    theme == "custom"
  end

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

  # Hex color values used for OG images
  THEME_COLORS = {
    "base"     => { bg: "#ffffff", text: "#334155", accent: "#4fbd9c" },
    "mint"     => { bg: "#f7faed", text: "#222222", accent: "#0080a1" },
    "lavender" => { bg: "#faf6ff", text: "#222222", accent: "#a8506f" },
    "coral"    => { bg: "#ffe9ee", text: "#222222", accent: "#955697" },
    "sand"     => { bg: "#fbf4ea", text: "#222222", accent: "#ad524d" },
    "sky"      => { bg: "#effbfd", text: "#222222", accent: "#3275b4" },
    "berry"    => { bg: "#ffeeff", text: "#222222", accent: "#ac5154" }
  }.freeze

  def og_theme_colors
    if custom_theme?
      {
        bg: custom_theme_bg_light.presence || "#ffffff",
        text: custom_theme_text_light.presence || "#334155",
        accent: custom_theme_accent_light.presence || "#334155"
      }
    else
      THEME_COLORS[theme] || THEME_COLORS["base"]
    end
  end
end
