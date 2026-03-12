class Post::Markdown
  def self.render(text)
    new(text).render
  end

  def initialize(text)
    @text = text
  end

  def render
    body, yaml = extract_front_matter
    attributes = yaml ? Post::FrontMatter.parse(yaml) : {}
    html = markdown.render(body)

    [ attributes, html ]
  end

  private

  def extract_front_matter
    stripped = @text.strip
    return [ @text, nil ] unless stripped.start_with?("---")

    parts = stripped.split("---", 3)
    return [ @text, nil ] unless parts.length >= 3

    [ parts[2], parts[1] ]
  end

  def markdown
    Redcarpet::Markdown.new(
      Renderer,
      autolink: true, tables: true, fenced_code_blocks: true, strikethrough: true
    )
  end

  class Renderer < Redcarpet::Render::HTML
    def block_code(code, language)
      %(<pre data-language="#{ERB::Util.html_escape(language.presence || "plain")}">#{ERB::Util.html_escape(code)}</pre>)
    end
  end
end
