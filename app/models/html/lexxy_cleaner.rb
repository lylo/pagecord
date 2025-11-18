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
      flatten_divs(@doc)
      wrap_inline_content(@doc)
      normalize_headings(@doc)
      @doc.to_html.strip
    end

    private

    # Post-order recursive flatten: process children first, then divs bottom-up
    def flatten_divs(node)
      node.children.each { |child| flatten_divs(child) }

      if node.element? && node.name == "div"
        if paragraph_like?(node)
          convert_to_paragraph(node)
        else
          node.replace(node.children)
        end
      end
    end

    def paragraph_like?(div)
      !div.children.any? { |c| c.element? && BLOCK_ELEMENTS.include?(c.name) }
    end

    def convert_to_paragraph(div)
      children = strip_br_edges(div.children.to_a)

      if children.empty? || children.all? { |c| c.text? && c.text.strip.empty? }
        div.remove
        return
      end

      p_node = build_paragraph(children)
      div.replace(p_node)
    end

    # Wrap remaining inline content in <p>s, splitting on <br><br>
    def wrap_inline_content(node)
      return if node.children.empty?

      blocks = []
      current_p_nodes = []

      node.children.each do |child|
        if child.element? && BLOCK_ELEMENTS.include?(child.name)
          # Flush current paragraph before adding block
          paragraph = build_paragraph(current_p_nodes)
          blocks << paragraph if paragraph
          current_p_nodes = []
          blocks << child
        else
          # Buffer inline or single <br>
          if child.element? && child.name == "br" && current_p_nodes.last&.element? && current_p_nodes.last.name == "br"
            # Double <br>: end current paragraph, skip the second
            paragraph = build_paragraph(current_p_nodes)
            blocks << paragraph if paragraph
            current_p_nodes = []
            next  # Skip this <br>
          elsif child.element? && child.name == "br" && current_p_nodes.empty?
            # Skip leading <br>
            next
          end
          current_p_nodes << child
        end
      end

      # Flush final paragraph
      paragraph = build_paragraph(current_p_nodes)
      blocks << paragraph if paragraph

      # Replace all children with blocks
      node.children.remove
      blocks.each { |b| node.add_child(b) }
    end

    # Build a <p> from nodes (shared helper)
    def build_paragraph(nodes)
      nodes = strip_br_edges(nodes)
      return nil if nodes.empty? || nodes.all? { |n| n.text? && n.text.strip.empty? }

      p_node = Nokogiri::XML::Node.new("p", @doc)
      nodes.each { |n| p_node.add_child(n.dup) }
      p_node
    end

    # Remove leading/trailing <br> and whitespace-only text nodes
    def strip_br_edges(nodes)
      nodes = nodes.dup

      nodes.shift while nodes.first && (
        (nodes.first.element? && nodes.first.name == "br") ||
        (nodes.first.text? && nodes.first.text.strip.empty?)
      )

      nodes.pop while nodes.last && (
        (nodes.last.element? && nodes.last.name == "br") ||
        (nodes.last.text? && nodes.last.text.strip.empty?)
      )

      nodes
    end

    def normalize_headings(node)
      node.css("h1").each { |h1| h1.name = "h2" }
    end
  end
end
