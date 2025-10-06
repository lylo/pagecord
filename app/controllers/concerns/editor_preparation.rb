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
        has_divs = original_content.include?("<div>")
        has_paragraphs = original_content.include?("<p>")
        return if !has_divs || has_paragraphs

        cleaned_content = Html::LexxyCleaner.clean(original_content)
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
