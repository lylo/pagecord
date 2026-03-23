class ExcerptBreak
  MARKER_PATTERN = /\{\{\s*(?:more|excerpt)\s*\}\}/i
  WP_COMMENT = /<!--\s*more\s*-->/i
  WP_ESCAPED = /&lt;!--\s*more\s*--&gt;/i

  def initialize(html)
    @html = html
  end

  def present?
    protected = protect_code_blocks(@html)
    protected.match?(MARKER_PATTERN) || protected.match?(WP_COMMENT) || protected.match?(WP_ESCAPED)
  end

  def excerpt
    doc = Nokogiri::HTML::DocumentFragment.parse(@html)
    marker = find_marker_node(doc)
    return @html unless marker

    block = block_ancestor(marker, doc)
    remove_from(block)
    doc.to_html
  end

  def strip
    doc = Nokogiri::HTML::DocumentFragment.parse(@html)
    marker = find_marker_node(doc)
    return @html unless marker

    block = block_ancestor(marker, doc)
    block.remove
    doc.to_html
  end

  def excerpt_plain_text
    doc = Nokogiri::HTML::DocumentFragment.parse(@html)
    marker = find_marker_node(doc)
    return "" unless marker

    block = block_ancestor(marker, doc)
    remove_from(block)

    doc.css("p, div, h1, h2, h3, h4, h5, h6, li, blockquote").each do |el|
      el.add_child(Nokogiri::XML::Text.new(" ", doc))
    end

    doc.text.gsub(/\s+/, " ").strip
  end

  private

    def find_marker_node(doc)
      doc.traverse do |node|
        next if inside_code_block?(node)

        if node.text? && node.text.match?(MARKER_PATTERN)
          return node
        end

        if node.comment? && node.text.match?(/\s*more\s*/i)
          return node
        end

        if node.text? && node.text.match?(WP_ESCAPED)
          return node
        end
      end

      nil
    end

    def inside_code_block?(node)
      ancestor = node.parent
      while ancestor
        return true if ancestor.element? && ancestor.name.in?(%w[pre code])
        ancestor = ancestor.parent
      end
      false
    end

    def block_ancestor(node, doc)
      current = node
      current = current.parent while current.parent && current.parent != doc
      current
    end

    def remove_from(node)
      while node
        next_node = node.next_sibling
        node.remove
        node = next_node
      end
    end

    def protect_code_blocks(html)
      html.gsub(%r{<(pre|code)[^>]*>.*?</\1>}m, "")
    end
end
