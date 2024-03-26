module Html
  class BodyExtraction < Transformation
    def transform(html)
      document = Nokogiri::HTML(html)
      body_tag = document.at_css("body")
      if body_tag
        body_tag.inner_html
      else
        ""
      end
    end
  end
end