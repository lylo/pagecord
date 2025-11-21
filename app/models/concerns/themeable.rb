module Themeable
  extend ActiveSupport::Concern

  THEMES = %w[base mint lavender coral sand sky berry custom].freeze
  FONTS = %w[sans serif mono].freeze
  PAGE_WIDTHS = %w[narrow standard wide].freeze

  included do
    validates :theme, inclusion: { in: THEMES, message: "%{value} is not a valid theme" }
    validates :font, inclusion: { in: FONTS, message: "%{value} is not a valid font" }
    validates :width, inclusion: { in: PAGE_WIDTHS, message: "%{value} is not a valid width" }
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
end
