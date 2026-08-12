module ReverseMarkdown
  module Converters
    class Pre < Base
      private

      def language(node)
        # Check data-language attribute first
        node["data-language"] ||
          language_from_highlight_class(node) ||
          language_from_confluence_class(node)
      end
    end

    # The stock converter flattens the caption to plain text, which turns a
    # PDF attachment's Download link into bare words. Convert each child
    # properly so links survive, joined with spaces because the whitespace
    # between the partial's tags is otherwise dropped.
    class FigCaption < Base
      def convert(node, state = {})
        content = node.children.map { |child| treat(child, state).squish }.reject(&:empty?).join(" ")
        content.empty? ? "" : "\n_#{content}_\n"
      end
    end
  end
end
