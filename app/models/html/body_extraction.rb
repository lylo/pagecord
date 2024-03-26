module Html
  class BodyExtraction < Transformation
    def transform(html)
      document = Nokogiri::HTML(html)
      document.at_css("body").inner_html
    end
  end
end