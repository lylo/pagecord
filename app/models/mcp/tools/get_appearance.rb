class Mcp::Tools::GetAppearance < Mcp::Tool
  describe "Get the blog's theme, font, width, layout and custom colours, its public URL, and its avatar's URL if it has one.", read_only: true

  def self.perform(blog)
    blog.as_json(only: Themeable::ATTRIBUTES).merge(url: blog_home_url(blog), avatar_url: (rails_public_blob_url(blog.avatar.blob) if blog.avatar.attached?))
  end
end
