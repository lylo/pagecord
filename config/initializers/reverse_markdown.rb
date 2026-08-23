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

    # Footnotes export as the "[^1]" syntax they were written in. Without these two
    # the gem has nothing for either half: a marker would pass through as raw
    # <sup> HTML, and the note list would come out as a plain numbered list at the
    # end of the post with nothing pointing at it.
    class Sup < PassThrough
      def convert(node, state = {})
        node.key?("data-footnote-ref") ? "[^#{node["data-footnote-ref"]}]" : super
      end
    end

    class Footnotes < Ol
      def convert(node, state = {})
        return super unless node.key?("data-footnotes")

        node.css("li").map { |note| definition(note, state) }.join
      end

      private

        def definition(note, state)
          "\n[^#{note["id"].to_s.delete_prefix("fn-")}]: #{treat_children(note, state).strip}\n"
        end
    end

    register :sup, Sup.new
    register :ol, Footnotes.new
  end
end
