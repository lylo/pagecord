# app/controllers/concerns/editor_preparation.rb
module EditorPreparation
  extend ActiveSupport::Concern

  private

  # Try and normalize content HTML for the editor (Trix or Lexxy).
  # This is because Trix doesn't support paragraphs while most inbound emails do,
  # and Lexxy needs to cope better with Trix-created HTML.
  def prepare_content_for_editor(post)
    original_content = post.content.body&.to_html
    return if original_content.blank?

    if current_features.enabled?(:lexxy)
      # Replace <h1> with <h2> for Lexxy
      cleaned_content = original_content.gsub(/<h1/i, "<h2").gsub(/<\/h1>/i, "</h2>")

      # Only clean if content has old div structure but no paragraph tags
      has_divs = cleaned_content.include?("<div>")
      has_paragraphs = cleaned_content.include?("<p>")
      if has_divs && !has_paragraphs
        # Remove all newlines except for within <pre> blocks
        cleaned_content = cleaned_content.gsub(/(<pre[\s\S]*?<\/pre>)|[\r\n]+/, '\1')

        # remove whitespace between tags (Lexxy can add a <br> tag in some cases)
        cleaned_content = cleaned_content.gsub(/>\s+</, "><")

        # replace double <br> from Trix with single <br>
        cleaned_content = cleaned_content.gsub(/<br><br><\/div>/, "<br></div>")

        # replace <div><br></div> with empty string (remove empty paragraphs)
        cleaned_content = cleaned_content.gsub(/<div><br><\/div>/, "")

        # replace <div><br> from Trix with just <div>
        cleaned_content = cleaned_content.gsub(/<div><br>/, "<div>")
      end

      if cleaned_content != original_content
        post.content = cleaned_content
      end
    else
      cleaned_content = Html::StripParagraphs.new.transform(original_content)

      # Replace <h2>, <h3>, <h4> with <h1>
      cleaned_content = cleaned_content.gsub(/<\/?h[2-4]>/i) { |tag| tag.sub(/h[2-4]/i, "h1") }

      # Remove all newlines except for within <pre> blocks
      cleaned_content = cleaned_content.gsub(/(<pre[\s\S]*?<\/pre>)|[\r\n]+/, '\1')

      cleaned_content = cleaned_content.gsub(/>\s+</, "><")

      # remove whitespace between tags (Trix seems to add a <br> tag in some cases)
      if original_content != cleaned_content
        post.content = cleaned_content
      end
    end
  end
end
