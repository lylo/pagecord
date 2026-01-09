require "nokogiri"

module EditorPreparation
  extend ActiveSupport::Concern

  private

    # Try and normalize content HTML for the editor (Lexxy).
    # This ensures that Lexxy copes better with legacy Trix-created HTML.
    def prepare_content_for_editor(post)
      original_content = post.content.body&.to_html
      return if original_content.blank?

      cleaned_content = original_content

      has_divs = original_content.include?("<div>")
      has_paragraphs = original_content.include?("<p>")
      return if !has_divs || has_paragraphs

      cleaned_content = Html::LexxyCleaner.clean(original_content)

      if cleaned_content != original_content
        post.content = cleaned_content
      end
    end
end
