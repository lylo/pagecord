class Mcp::Tools::GetCustomCode < Mcp::Tool
  FIELDS = Blog::CustomCode::ATTRIBUTES + Blog::CustomCode::SUBSCRIBER_ATTRIBUTES

  describe "Get the blog's custom CSS, footer HTML, and head and body HTML.", read_only: true

  def self.perform(blog)
    blog.as_json(only: FIELDS)
  end
end
