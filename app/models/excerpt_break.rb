class ExcerptBreak
  MARKER_BLOCK = /\A\s*\{\{\s*(?:more|excerpt)\s*\}\}\s*\z/i
  WP_COMMENT_BLOCK = /\A\s*<!--\s*more\s*-->\s*\z/i

  class << self
    # Returns HTML before the first marker, or nil if no marker found.
    # Used on save to pre-compute the excerpt column.
    def extract(html)
      doc = parse(html)
      block = find_marker_block(doc)
      return nil unless block

      remove_from(block)
      doc.to_html
    end

    # Removes the marker block from HTML, keeps all other content.
    # Used at render time for full post view, RSS, email.
    def strip(html)
      doc = parse(html)
      block = find_marker_block(doc)
      return html unless block

      block.remove
      doc.to_html
    end

    private

      def parse(html)
        Nokogiri::HTML::DocumentFragment.parse(html)
      end

      # Only matches markers in top-level blocks — the marker must be the sole
      # content of a direct child element (e.g. <p>{{ more }}</p>), or a top-level
      # HTML comment (<!--more-->). Markers nested inside lists, blockquotes,
      # tables etc. are ignored.
      def find_marker_block(doc)
        doc.children.each do |child|
          if child.element? && !child.at_css("*")
            return child if child.text.match?(MARKER_BLOCK) || child.text.match?(WP_COMMENT_BLOCK)
          elsif child.comment? && child.text.strip.match?(/\Amore\z/i)
            return child
          end
        end
        nil
      end

      def remove_from(node)
        while node
          next_node = node.next_sibling
          node.remove
          node = next_node
        end
      end
  end
end
