module Html
  class PlainTextToHtml < Transformation
    def transform(plain_text)
      # Escape any HTML special characters to prevent injection issues
      escaped_text = CGI.escapeHTML(plain_text)

      html_text = escaped_text.gsub(/\n\n+/, '<br><br>')

      html_text.gsub(/\n/, '<br>')
    end
  end
end