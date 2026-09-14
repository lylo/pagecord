module Html
  class ExternalLinksInNewTab < Transformation
    def initialize(blog)
      @blog = blog
    end

    def transform(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      doc.css("a[href]").each do |link|
        next unless @blog.external_url?(link["href"])

        link["target"] = "_blank"
        link["rel"] = [ *link["rel"].to_s.split, "noopener" ].uniq.join(" ")
      end

      doc.to_html
    end
  end
end
