module Html
  class ExtractTags < Transformation
    HASHTAG_REGEX = /#([a-zA-Z0-9-]+)(?=\p{Space}|$|#)/

    def transform(input)
      @tags = []

      # Step 1: Convert to plain text (works for both HTML and plain text)
      text = ActionText::Content.new(input).to_plain_text

      # Step 2: Extract hashtags from hashtag-only lines at the end
      extract_tags_from_trailing_lines(text)

      # Step 3: Remove extracted hashtags from original input
      if @tags.any?
        result = input.dup
        @tags.uniq.each do |tag|
          result = result.gsub(/##{Regexp.escape(tag)}(?=\p{Space}|$|#|<)/i, "")
        end
        result
      else
        input
      end
    end

    def tags
      (@tags || []).uniq.sort
    end

    private

      def extract_tags_from_trailing_lines(text)
        lines = text.lines.map(&:chomp)

        # Remove empty lines from the end (including nbsp and other Unicode whitespace)
        lines.pop while lines.last && blank_line?(lines.last)

        # Extract hashtags from lines at the end
        while lines.any?
          line = lines.last.strip

          # Skip empty lines
          if blank_line?(line)
            lines.pop
            next
          end

          hashtags = extract_hashtags_from_line(line)

          if hashtags.any?
            # Check if line contains ONLY hashtag-like patterns (valid and invalid)
            if line.strip.match?(/\A\s*(#\S+\s*)+\z/)
              # Line contains only hashtag-like patterns, extract the valid ones
              @tags.concat(hashtags)
              lines.pop
            else
              # Line has other content mixed with hashtags, don't extract anything, stop
              break
            end
          else
            # No valid hashtags in this line, stop processing
            break
          end
        end
      end

      def extract_hashtags_from_line(line)
        potential_tags = line.scan(HASHTAG_REGEX).flatten
        valid_tags = potential_tags.select { |tag| tag.match?(Taggable::VALID_TAG_FORMAT) }
        valid_tags.map(&:downcase)
      end

      # Check if a line is blank (including nbsp and other Unicode whitespace)
      def blank_line?(line)
        line.gsub(/\p{Space}/, "").empty?
      end
  end
end
