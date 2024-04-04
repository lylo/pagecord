module Html
  class MonospaceDetection < Transformation
    def transform(html)
      document = Nokogiri::HTML.fragment(html)

      replace_style_tags_with_code_tags(document)
      replace_font_tags_with_code_tags(document)

      document.to_html
    end

    private

      # Fastmail wraps monospace lines in <span style="font-family: monospace"> tags
      def replace_style_tags_with_code_tags(document)
        document.css("div[style], span[style]").each do |element|
          styles = element['style'].downcase.split(';')
          font_family = styles.find { |style| style.strip.start_with?('font-family') }
          if font_family && font_family.include?('monospace')
            insert_code_tag(element)
          end
        end
      end

      # Gmail wraps monospace in <font face="monospace"> tags
      def replace_font_tags_with_code_tags(document)
        document.css("font[face]").each do |element|
          insert_code_tag(element) if is_monospace_font?(element["face"])
        end
      end

      def insert_code_tag(element)
        code = Nokogiri::XML::Node.new "code", element.document
        code.content = element.content
        element.replace code
      end

      MONOSPACE_FONTS = ["consolas", "courier", "inconsolata", "lucida console",
                         "menlo", "monaco", "monospace", "sf mono", "source code pro"].freeze

      def is_monospace_font?(font)
        MONOSPACE_FONTS.each do |monospace_font|
          return true if font.downcase.include?(monospace_font.to_s)
        end
      end
  end
end