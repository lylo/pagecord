module Html
  class HeadingIds < Transformation
    def transform(html)
      return html if html.blank?

      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      counts = Hash.new(0)

      doc.css("h1, h2, h3, h4, h5, h6").each do |heading|
        next if heading["id"].present?

        slug = heading.text.parameterize.truncate(64, omission: "")
        next if slug.blank?

        count = counts[slug]
        counts[slug] += 1
        heading["id"] = count.zero? ? slug : "#{slug}-#{count}"
      end

      doc.to_html
    end
  end
end
