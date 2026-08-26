class Micropub::SourceContent
  def initialize(html)
    @html = html
  end

  # A post that is a single plain paragraph round-trips as text, so a client
  # editing it gets back what it sent rather than markup it has to unwrap.
  # Anything richer keeps its HTML.
  def value
    plain_paragraph? ? elements.first.text : { html: html }
  end

  private

    attr_reader :html

    def plain_paragraph?
      elements.one? && elements.first.name == "p" && elements.first.element_children.empty?
    end

    def elements
      @elements ||= Nokogiri::HTML::DocumentFragment.parse(html).children.select(&:element?)
    end
end
