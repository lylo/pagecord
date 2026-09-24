class Mcp::UpdateAppearance < Mcp::Tool
  COLOUR = { type: "string", description: "Hex colour such as #1e293b. Used when theme is custom." }.freeze

  tool_name "update_appearance"
  description "Change how the blog looks. Only the fields given change."
  input_schema(
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
      custom_theme_accent_dark: COLOUR,
      custom_css: { type: "string", description: "Custom CSS for the blog, up to 16KB. Replaces the existing CSS." }
    }
  )
  annotations(idempotent_hint: true)

  def self.perform(blog, **arguments)
    blog.update!(arguments)
    blog.as_json(only: Mcp::GetAppearance::FIELDS)
  end
end
