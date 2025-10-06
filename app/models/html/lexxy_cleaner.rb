module Html
  class LexxyCleaner
    BLOCK_ELEMENTS = %w[
      figure action-text-attachment blockquote pre ul ol table hr
      h1 h2 h3 h4 h5 h6 p
    ].freeze

    def self.clean(html)
      new(html).clean
    end

    def initialize(html)
      @doc = Nokogiri::HTML::DocumentFragment.parse(html)
    end

    def clean
      convert_divs_to_paragraphs(@doc)
      flatten_divs(@doc)
      process_node(@doc)
      normalize_headings(@doc)
      @doc.to_html.strip
    end

    private

    # Convert divs that contain only inline content to paragraphs
    # This preserves the semantic structure where each div represents a paragraph
    def convert_divs_to_paragraphs(node)
      node.css("div").each do |div|
        # Check if div contains only inline content (no block elements)
        has_block_elements = div.children.any? { |child| child.element? && BLOCK_ELEMENTS.include?(child.name) }
        has_nested_divs = div.css("div").any?

        # Convert to <p> if it's a "paragraph-like" div (inline content only)
        if !has_block_elements && !has_nested_divs
          # Clean up leading and trailing <br> tags
          children = div.children.to_a

          # Remove leading <br> tags
          while children.first && br_element?(children.first)
            children.shift
          end

          # Remove trailing <br> tags
          while children.last && br_element?(children.last)
            children.pop
          end

          # Skip empty divs
          next if children.empty? || children.all? { |c| whitespace_only?(c) }

          p_node = Nokogiri::XML::Node.new("p", @doc)
          children.each { |child| p_node.add_child(child.dup) }
          div.replace(p_node)
        end
      end
    end

    # Recursively flatten all remaining <div> wrappers, promoting their children
    def flatten_divs(node)
      node.css("div").each do |div|
        div.replace(div.children)
      end
    end

    # Convert h1 elements to h2 (Lexxy uses h2 as the primary heading)
    def normalize_headings(node)
      node.css("h1").each { |h1| h1.name = "h2" }
    end

    # Process a node to extract blocks and inline content
    def process_node(node)
      blocks = []
      current_inline = []

      node.children.each do |child|
        if block_element?(child)
          # Flush any pending inline content as a paragraph
          unless current_inline.empty?
            para = wrap_paragraph(current_inline)
            blocks << para if para
          end
          current_inline = []

          # Add the block element directly
          blocks << child.dup
        elsif br_element?(child)
          # Collect <br> elements
          current_inline << child
        elsif text_node?(child) && child.text.strip.empty?
          # Skip whitespace-only text nodes between blocks
          current_inline << child unless current_inline.empty?
        else
          # Inline content (text, links, spans, etc.)
          current_inline << child
        end
      end

      # Flush any remaining inline content
      unless current_inline.empty?
        para = wrap_paragraph(current_inline)
        blocks << para if para
      end

      # Replace node's children with processed blocks
      node.children.remove
      blocks.compact.each { |block| node.add_child(block) }
    end

    # Wrap inline content in <p>, splitting at <br><br> sequences
    def wrap_paragraph(inline_nodes)
      paragraphs = []
      current_para = []

      i = 0
      while i < inline_nodes.length
        node = inline_nodes[i]

        # Check for <br><br> sequence (paragraph break)
        if br_element?(node) && i + 1 < inline_nodes.length && br_element?(inline_nodes[i + 1])
          # Flush current paragraph
          para = create_paragraph(current_para)
          paragraphs << para if para
          current_para = []
          i += 2 # Skip both <br> elements

          # Skip any additional whitespace or <br>s
          while i < inline_nodes.length && (whitespace_only?(inline_nodes[i]) || br_element?(inline_nodes[i]))
            i += 1
          end
        elsif br_element?(node) && current_para.empty?
          # Skip leading <br>
          i += 1
        else
          current_para << node
          i += 1
        end
      end

      # Flush final paragraph
      unless current_para.empty?
        para = create_paragraph(current_para)
        paragraphs << para if para
      end

      # Filter out any nil values
      paragraphs.compact!

      # Return a document fragment containing all paragraphs
      return nil if paragraphs.empty?

      if paragraphs.length == 1
        paragraphs.first
      else
        fragment = Nokogiri::HTML::DocumentFragment.parse("")
        paragraphs.each { |p| fragment.add_child(p) }
        fragment
      end
    end

    def create_paragraph(nodes)
      return nil if nodes.all? { |n| whitespace_only?(n) || br_element?(n) }

      # Clean trailing <br>s
      nodes = nodes.dup
      nodes.pop while nodes.last && br_element?(nodes.last)

      return nil if nodes.empty?

      p = Nokogiri::XML::Node.new("p", @doc)
      nodes.each { |node| p.add_child(node.dup) }
      p
    end

    def block_element?(node)
      node.element? && BLOCK_ELEMENTS.include?(node.name)
    end

    def br_element?(node)
      node.element? && node.name == "br"
    end

    def text_node?(node)
      node.text?
    end

    def whitespace_only?(node)
      text_node?(node) && node.text.strip.empty?
    end
  end
end
