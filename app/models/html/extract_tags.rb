module Html
  class ExtractTags < Transformation
    HASHTAG_REGEX = /#([a-zA-Z0-9-]+)(?=\s|$)/

    def transform(input)
      @tags = []

      if input.include?("<")
        transform_html(input)
      else
        transform_plaintext(input)
      end
    end

    def tags
      @tags || []
    end

    private

      def transform_html(html)
        document = Nokogiri::HTML.fragment(html)
        last_element = find_last_text_element(document)
        return html unless last_element

        text = last_element.text.strip
        return html unless text.match?(HASHTAG_REGEX)

        @tags = extract_tags(text)
        cleaned_text = remove_hashtag_lines(text)

        if cleaned_text.empty?
          last_element.remove
        else
          last_element.content = cleaned_text
        end

        document.to_html
      end

      def transform_plaintext(text)
        lines = text.lines.map(&:strip)
        tag_lines = []

        # Remove empty lines from the end first
        lines.pop while lines.last&.empty?

        # Then collect hashtag lines from the end
        while lines.any? && lines.last.match?(HASHTAG_REGEX)
          tag_lines.unshift(lines.pop)
        end

        return text unless tag_lines.any?

        @tags = tag_lines.flat_map { |line| extract_tags(line) }.uniq.sort
        lines.join("\n").strip
      end

      def extract_tags(text)
        # Extract potential hashtags and then validate them
        potential_tags = text.scan(HASHTAG_REGEX).flatten

        # Filter to only valid tags (letters, numbers, hyphens only)
        valid_tags = potential_tags.select { |tag| tag.match?(/\A[a-zA-Z0-9-]+\z/) }

        valid_tags.map(&:downcase).uniq.sort
      end

      def remove_hashtag_lines(text)
        lines = text.lines.map(&:strip)
        # Remove empty lines from the end first
        lines.pop while lines.last&.empty?
        # Then remove hashtag lines from the end
        lines.pop while lines.last&.match?(HASHTAG_REGEX)
        lines.join("\n").strip
      end

      def find_last_text_element(document)
        # Finds last block-level element with non-empty text content
        document.css("p, div, span, li").reverse.find { |el| el.text.strip.present? }
      end
  end
end
