module Html
  class LexxyCleaner
    BLOCK_ELEMENTS = %w[
      figure action-text-attachment blockquote pre ul ol table hr
      h1 h2 h3 h4 h5 h6 p img video audio
    ].freeze

    def self.clean(html)
      new(html).clean
    end

    def initialize(html)
      @doc = Nokogiri::HTML::DocumentFragment.parse(html)
    end

    def clean
      process_divs(@doc)
      wrap_inline_content(@doc)
      normalize_headings(@doc)
      @doc.to_html.strip
    end

    private

    # Process divs until none remain: convert paragraph-like divs to <p>, flatten wrapper divs
    def process_divs(node)
      while node.css("div").any?
        node.css("div").each do |div|
          if paragraph_like?(div)
            convert_to_paragraph(div)
          else
            div.replace(div.children)
          end
        end
      end
    end

    def paragraph_like?(div)
      !div.children.any? { |c| c.element? && BLOCK_ELEMENTS.include?(c.name) } &&
        div.css("div").empty?
    end

    def convert_to_paragraph(div)
      children = strip_br_edges(div.children.to_a)

      if children.empty? || children.all? { |c| c.text? && c.text.strip.empty? }
        div.remove
        return
      end

      p_node = Nokogiri::XML::Node.new("p", @doc)
      children.each { |c| p_node.add_child(c.dup) }
      div.replace(p_node)
    end

    # Wrap any remaining inline content in paragraphs, splitting on <br><br>
    def wrap_inline_content(node)
      blocks = []
      inline_buffer = []

      node.children.to_a.each do |child|
        if child.element? && BLOCK_ELEMENTS.include?(child.name)
          # Flush inline buffer before adding block
          blocks.concat(create_paragraphs_from_buffer(inline_buffer))
          inline_buffer = []
          blocks << child
        else
          inline_buffer << child
        end
      end

      # Flush remaining inline content
      blocks.concat(create_paragraphs_from_buffer(inline_buffer))

      # Replace children
      node.children.remove
      blocks.each { |b| node.add_child(b) }
    end

    # Split inline buffer on <br><br> and create paragraphs
    def create_paragraphs_from_buffer(nodes)
      return [] if nodes.empty?

      paragraphs = []
      current = []

      nodes.each_with_index do |node, i|
        if node.name == "br" && nodes[i + 1]&.name == "br"
          # Found <br><br> - flush current paragraph
          para = build_paragraph(current)
          paragraphs << para if para
          current = []
        elsif node.name == "br" && nodes[i - 1]&.name == "br"
          # Skip second br in sequence
          next
        elsif node.name == "br" && current.empty?
          # Skip leading br
          next
        else
          current << node
        end
      end

      # Flush final paragraph
      para = build_paragraph(current)
      paragraphs << para if para

      paragraphs
    end

    def build_paragraph(nodes)
      nodes = strip_br_edges(nodes)
      return nil if nodes.empty?
      return nil if nodes.all? { |n| n.text? && n.text.strip.empty? }

      p = Nokogiri::XML::Node.new("p", @doc)
      nodes.each { |n| p.add_child(n.dup) }
      p
    end

    # Remove leading/trailing <br> and whitespace-only text nodes
    def strip_br_edges(nodes)
      nodes = nodes.dup

      # Remove leading
      nodes.shift while nodes.first && (nodes.first.name == "br" ||
                                        (nodes.first.text? && nodes.first.text.strip.empty?))

      # Remove trailing
      nodes.pop while nodes.last && (nodes.last.name == "br" ||
                                     (nodes.last.text? && nodes.last.text.strip.empty?))

      nodes
    end

    def normalize_headings(node)
      node.css("h1").each { |h1| h1.name = "h2" }
    end
  end
end
