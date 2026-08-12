module Html
  # An excerpt stops at the excerpt break, but the footnote list sits at the end of
  # the post, so a marker in the excerpt links to a note that is not on the page.
  # Worse, on an index page it can land on another post's note, since the numbers
  # restart per post. Dropping both halves leaves the excerpt reading cleanly.
  class StripFootnotes < Transformation
    def transform(html)
      return html if html.blank?

      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      doc.css("sup[data-footnote-ref], ol[data-footnotes]").each(&:remove)
      doc.to_html
    end
  end
end
