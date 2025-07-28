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

        # Work backwards through elements to find consecutive hashtag-only elements
        elements_to_remove = []
        all_tags = []

        # Get all block-level elements with text content
        elements = document.css("p, div, span, li").select { |el| el.text.strip.present? }

        # Work backwards from the last element
        elements.reverse_each do |element|
          text = element.text.strip

          # Check if this element contains only hashtags
          hashtags = extract_tags(text)
          text_without_hashtags = text.gsub(HASHTAG_REGEX, "").strip

          if hashtags.any? && text_without_hashtags.empty?
            # This element contains only hashtags
            all_tags.concat(hashtags)
            elements_to_remove << element
          else
            # Found non-hashtag content, stop processing
            break
          end
        end

        # Remove hashtag-only elements and set tags
        elements_to_remove.each(&:remove)
        @tags = all_tags.uniq.sort

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
  end
end
