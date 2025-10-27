class SocialPreview
  def initialize(post)
    @post = post
    @blog = post.blog
  end

  def to_png
    MiniMagick::Image.read(to_svg, ".svg").tap { _1.format("png") }.to_blob
  end

  def to_svg
    ApplicationController.render(
      template: "social_previews/og_image",
      locals: view_assigns,
      layout: false,
      formats: [ :svg ]
    )
  end

  private

  def view_assigns
    {
      post: @post,
      blog: @blog,
      title_lines: wrap_title,
      favicon_data_uri: favicon_data_uri,
      font_family: font_family,
      theme_colors: theme_colors,
      layout: layout
    }
  end

  def wrap_title
    max_chars = { "mono" => 20, "serif" => 28 }.fetch(@blog.font, 30)
    words = @post.display_title.split
    lines = [ [] ]
    words.each do |word|
      test = (lines.last + [ word ]).join(" ")
      if test.length > max_chars && lines.last.any?
        lines << [ word ]
      else
        lines.last << word
      end
    end
    lines.map { |line| line.join(" ") }[0, 3]
  end

  def favicon_data_uri
    if @blog.avatar.attached?
      data = @blog.avatar.blob.download
      "data:#{@blog.avatar.content_type};base64,#{Base64.strict_encode64(data)}"
    else
      svg = Rails.root.join("app/assets/images/favicon.svg").read
      "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
    end
  rescue => e
    Rails.logger.error("favicon error: #{e.message}")
    nil
  end

  def font_family
    {
      "serif" => "'Lora Variable', 'Lora', Georgia, serif",
      "mono"  => "'IBM Plex Mono', 'Courier New', monospace"
    }.fetch(@blog.font, "InterVariable, Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif")
  end

  def theme_colors
    {
      "mint"     => { bg: "#f8fffe", text: "#1a1a1a", accent: "#2d7a6e" },
      "lavender" => { bg: "#faf8fe", text: "#1a1a1a", accent: "#7c3aed" },
      "coral"    => { bg: "#fef7f5", text: "#1a1a1a", accent: "#dc2626" },
      "sand"     => { bg: "#fefcf8", text: "#1a1a1a", accent: "#d97706" },
      "sky"      => { bg: "#f8fbfe", text: "#1a1a1a", accent: "#2563eb" },
      "berry"    => { bg: "#fef8fb", text: "#1a1a1a", accent: "#be185d" }
    }.fetch(@blog.theme, { bg: "#ffffff", text: "#0f172a", accent: "#4fbd9c" })
  end

  def layout
    padding = 60
    favicon_size = 96
    title_line_height = 85
    blog_name_font_size = 56
    canvas_height = 630

    title_height = wrap_title.size * title_line_height
    total = favicon_size + title_height + blog_name_font_size
    gap = (canvas_height - total) / 4.0

    {
      padding: padding,
      favicon_y: gap,
      favicon_center_x: padding + favicon_size / 2.0,
      favicon_center_y: gap + favicon_size / 2.0,
      favicon_size: favicon_size,
      title_y: gap + favicon_size + gap * 0.7 + 72,
      title_line_height: title_line_height,
      blog_name_y: canvas_height - gap
    }
  end
end
