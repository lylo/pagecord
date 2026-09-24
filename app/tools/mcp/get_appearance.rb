class Mcp::GetAppearance < Mcp::Tool
  FIELDS = Api::Settings::AppearanceController::FIELDS + %i[ custom_css ]

  tool_name "get_appearance"
  description "Get the blog's theme, font, width, layout, custom colours and custom CSS."
  input_schema(properties: {})
  annotations(read_only_hint: true)

  def self.perform(blog)
    blog.as_json(only: FIELDS)
  end
end
