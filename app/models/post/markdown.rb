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
    # Obsidian's callout types, with its aliases folded onto the canonical type
    # they render as. https://obsidian.md/help/callouts
    CALLOUT_TYPES = {
      "note" => "note", "info" => "info", "todo" => "todo",
      "abstract" => "abstract", "summary" => "abstract", "tldr" => "abstract",
      "tip" => "tip", "hint" => "tip", "important" => "tip",
      "success" => "success", "check" => "success", "done" => "success",
      "question" => "question", "help" => "question", "faq" => "question",
      "warning" => "warning", "caution" => "warning", "attention" => "warning",
      "failure" => "failure", "fail" => "failure", "missing" => "failure",
      "danger" => "danger", "error" => "danger",
      "bug" => "bug", "example" => "example",
      "quote" => "quote", "cite" => "quote"
    }.freeze

    # Obsidian renders an unrecognised type as a note, keeping the word you typed
    # as the title.
    DEFAULT_CALLOUT_TYPE = "note"

    # Redcarpet hands block_quote the already-rendered inner HTML, so a callout
    # marker arrives as the start of the first paragraph's content.
    MARKER = /\A\[!(?<type>\w+)\][ \t]*/

    def block_code(code, language)
      %(<pre data-language="#{ERB::Util.html_escape(language.presence || "plain")}">#{ERB::Util.html_escape(code.chomp)}</pre>)
    end

    # Redcarpet follows Markdown.pl, where a blank line does not end a quote, so
    # adjacent callouts arrive merged into one. Slicing at each marker restores
    # the separate callouts Obsidian and CommonMark produce.
    def block_quote(quote)
      fragment = Nokogiri::HTML::DocumentFragment.parse(quote)
      segments = fragment.element_children.slice_before { |block| marker_for(block) }

      segments.map { |blocks| render_segment(blocks) }.join
    end

    private
      def marker_for(block)
        block.name == "p" ? block.inner_html.match(MARKER) : nil
      end

      def render_segment(blocks)
        marker = marker_for(blocks.first)
        return blockquote(blocks) unless marker

        title, body = blocks.first.inner_html.delete_prefix(marker[0]).split("\n", 2)
        type = CALLOUT_TYPES.fetch(marker[:type].downcase, DEFAULT_CALLOUT_TYPE)

        paragraphs = [ %(<p data-callout-title>#{title.presence || marker[:type].capitalize}</p>) ]
        paragraphs << "<p>#{body}</p>" if body.present?

        callout(type, paragraphs + blocks.drop(1).map(&:to_html))
      end

      def blockquote(blocks)
        "<blockquote>\n#{blocks.map(&:to_html).join("\n")}\n</blockquote>\n"
      end

      def callout(type, paragraphs)
        %(<aside data-callout="#{type}">\n#{paragraphs.join("\n")}\n</aside>\n)
      end
  end
end
