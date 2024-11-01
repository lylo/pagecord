module Html
  class Utf8Encoding < Transformation
    def transform(html)
      html.force_encoding("UTF-8")
    end
  end
end
