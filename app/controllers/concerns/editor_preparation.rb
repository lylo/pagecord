require "nokogiri"

module EditorPreparation
  extend ActiveSupport::Concern

  private

    # Try and normalize content HTML for the editor (Trix or Lexxy).
    # This is because Trix doesn't support paragraphs while most inbound emails do,
    # and Lexxy needs to cope better with Trix-created HTML.
    def prepare_content_for_editor(post)
      original_content = post.content.body&.to_html
      return if original_content.blank?

      cleaned_content = original_content

      if current_features.enabled?(:lexxy)
        doc = Nokogiri::HTML::DocumentFragment.parse(original_content)

        # Shift <h1> to <h2>
        doc.css("h1").each { |node| node.name = "h2" }

        # Mark divs that contain other divs (wrapper divs) - don't convert these
        wrapper_divs = []
        doc.css("div").each do |node|
          if node.css("div").any?
            wrapper_divs << node
          end
        end

        # Convert non-wrapper divs to paragraphs (cleaning up Trix-created content)
        doc.css("div").each do |node|
          # Skip wrapper divs
          next if wrapper_divs.include?(node)

          # Check if div only has br tags (ignoring whitespace text nodes)
          only_br_tags = node.children.all? { |c| c.name == "br" || (c.text? && c.content.strip.empty?) }

          # Remove empty divs or divs with only br tags
          if node.content.strip.empty? && only_br_tags
            node.remove
          else
            # Remove leading whitespace and br tags
            loop do
              first = node.children.first
              break unless first
              if first.text? && first.content.strip.empty?
                first.remove
              elsif first.name == "br"
                first.remove
                break # Only remove one leading br
              else
                break
              end
            end

            # Remove trailing whitespace and br tags
            loop do
              last = node.children.last
              break unless last
              if last.text? && last.content.strip.empty?
                last.remove
              elsif last.name == "br"
                last.remove
              else
                break
              end
            end

            # Convert div to paragraph
            node.name = "p"
          end
        end

        # Remove wrapper divs that are now empty
        wrapper_divs.each do |node|
          node.replace(node.children) if node.parent
        end

        cleaned_content = doc.to_html
      else
        doc = Nokogiri::HTML::DocumentFragment.parse(original_content)

        # Convert paragraphs to divs with <br><br>
        doc.css("p").each do |p|
          new_div = Nokogiri::XML::Node.new("div", doc)
          new_div.inner_html = p.inner_html + "<br><br>"
          p.replace(new_div)
        end

        # Convert h2, h3, h4 to h1
        doc.css("h2, h3, h4").each { |node| node.name = "h1" }

        cleaned_content = doc.to_html

        # Remove all newlines except for within <pre> blocks
        cleaned_content = cleaned_content.gsub(/(<pre[\s\S]*?<\/pre>)|[\r\n]+/, '\1')

        # Remove whitespace between tags
        cleaned_content = cleaned_content.gsub(/>\s+</, "><")
      end

      if cleaned_content != original_content
        post.content = cleaned_content
      end
    end
end
