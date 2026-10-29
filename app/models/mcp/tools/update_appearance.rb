class Mcp::Tools::UpdateAppearance < Mcp::Tool
  COLOUR = { type: "string", description: "Hex colour such as #1e293b. Used when theme is custom." }.freeze

  describe "Change how the blog looks. Only the fields given change.",
    properties: {
      theme: { type: "string", enum: Themeable::THEMES },
      font: { type: "string", enum: Themeable::FONTS },
      width: { type: "string", enum: Themeable::PAGE_WIDTHS },
      layout: { type: "string", enum: Blog.layouts.keys },
      custom_theme_bg_light: COLOUR,
      custom_theme_text_light: COLOUR,
      custom_theme_accent_light: COLOUR,
      custom_theme_bg_dark: COLOUR,
      custom_theme_text_dark: COLOUR,
      custom_theme_accent_dark: COLOUR
    },
    idempotent: true, destructive: true

  def self.perform(blog, **arguments)
    blog.update!(arguments)
    Mcp::Tools::GetAppearance.perform(blog)
  end
end
