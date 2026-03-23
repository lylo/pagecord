class ExcerptBreak
  MARKER = /\{\{\s*(?:more|excerpt)\s*\}\}/i
  WP_COMMENT = /<!--\s*more\s*-->/i
  WP_ESCAPED = /&lt;!--\s*more\s*--&gt;/i

  STRIP_PATTERNS = [
    /<p>\s*\{\{\s*(?:more|excerpt)\s*\}\}\s*<\/p>/i,
    /<!--\s*more\s*-->/i,
    /<p>\s*&lt;!--\s*more\s*--&gt;\s*<\/p>/i
  ]

  # Returns HTML before the first marker, or nil if no marker found.
  # Used once on save to pre-compute the excerpt column.
  def self.extract(html)
    new(html).excerpt
  end

  # Removes the marker paragraph from HTML. Simple regex, no Nokogiri.
  # Used at render time for full post view, RSS, email.
  def self.strip(html)
    STRIP_PATTERNS.reduce(html) { |content, pattern| content.gsub(pattern, "") }
  end

  def initialize(html)
    @html = html
  end

  def present?
    protected = protect_code_blocks(@html)
    protected.match?(MARKER) || protected.match?(WP_COMMENT) || protected.match?(WP_ESCAPED)
  end

  def excerpt
    doc = Nokogiri::HTML::DocumentFragment.parse(@html)
    marker = find_marker_node(doc)
    return nil unless marker

    block = block_ancestor(marker, doc)
    remove_from(block)
    doc.to_html
  end

  private

    def find_marker_node(doc)
      doc.traverse do |node|
        next if inside_code_block?(node)

        return node if node.text? && (node.text.match?(MARKER) || node.text.match?(WP_COMMENT))
        return node if node.comment? && node.text.match?(/\s*more\s*/i)
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
