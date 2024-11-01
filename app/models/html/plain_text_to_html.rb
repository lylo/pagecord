module Html
  class PlainTextToHtml < Transformation
    include ActionView::Helpers::TextHelper

    def transform(plain_text)
      # Escape any HTML special characters to prevent injection issues
      escaped_text = CGI.escapeHTML(plain_text)

      simple_format(escaped_text)
    end
  end
end
