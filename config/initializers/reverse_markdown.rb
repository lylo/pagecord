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
  end
end
