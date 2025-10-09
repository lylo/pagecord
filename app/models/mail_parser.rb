class MailParser
  include Html::AttachmentPreview
  include ActionView::Helpers::SanitizeHelper

  def initialize(mail, process_attachments: true)
    @mail = mail

    @attachments = []
    @processed_attachment_ids = Set.new  # Track attachments processed inline
    store_attachments if process_attachments

    @extract_tags = Html::ExtractTags.new

    @html_pipeline = [
      Html::BodyExtraction.new,
      Html::MonospaceDetection.new,
      Html::ImageUnfurl.new,
      Html::InlineAttachments.new(@attachments),
      @extract_tags,
      Html::Sanitize.new
    ]

    @plain_text_pipeline = [
      Html::PlainTextToHtml.new,
      @extract_tags,
      Html::ImageUnfurl.new
    ]
  end

  def subject
    @title ||= @mail.subject&.strip
  end

  def body
    @body ||= parse_body
  end

  def attachments
    @attachments&.map { |attachment| attachment[:blob] } || []
  end

  def has_attachments?
    !attachments.empty?
  end

  def tags
    # Ensure body has been parsed to extract tags
    body if @extract_tags
    @extract_tags&.tags || []
  end

  def is_blank?
    subject_blank? && body_blank?
  end

  def subject_blank?
    subject.blank?
  end

  def body_blank?
    sanitized_body.strip.blank? && !has_attachments?
  end

  private

    def html_transform(html)
      transform(@html_pipeline, html)
    end

    def plain_text_transform(html)
      transform(@plain_text_pipeline, html)
    end

    def transform(pipeline, html)
      charset = @mail.charset || "UTF-8"
      if charset.downcase != "utf-8"
        Rails.logger.info "Converting mail from #{charset} to UTF-8"
        decoded = html.encode(charset, "UTF-8", invalid: :replace, undef: :replace, replace: "")
        html = decoded.force_encoding("UTF-8")
      end

      pipeline.each do |transformation|
        html = transformation.transform(html)
      end
      html
    end

    def parse_body
      if @mail.multipart?
        # Let the Mail gem handle multipart/alternative - it picks the best part
        if @mail.html_part
          html_content = collect_html_content
          transformed_html = html_transform(html_content)
          transformed_html << process_unreferenced_attachments(html_content)
          transformed_html
        elsif @mail.text_part
          plain_text_transform(@mail.text_part.decoded)
        else
          # No html_part or text_part - process parts manually
          # This handles plain text + inline images (Apple Mail default)
          nodes = []
          @mail.parts.each do |part|
            if part.text?
              nodes << plain_text_transform(part.decoded)
            elsif part.attachment? && media_attachment?(part)
              attachment = find_attachment_from_part(part)
              nodes << process_attachment(attachment) if attachment
            end
          end
          nodes.join("\n")
        end
      else
        # Not multipart
        case @mail.content_type
        when /text\/plain/
          plain_text_transform(@mail.decoded)
        when /text\/html/
          html_transform(@mail.decoded)
        else
          raise "Unknown content type #{@mail.content_type}"
        end
      end
    end

    # Collects HTML content from the email
    # Returns early for standard cases, delegates to edge case handler if needed
    def collect_html_content
      html_content = @mail.html_part.decoded

      # Check if this is the Apple Mail edge case
      if apple_mail_multipart_mixed_in_alternative?
        return handle_apple_mail_edge_case
      end

      html_content
    end

    # Apple Mail violates RFC 2046 by nesting multipart/mixed (with multiple HTML
    # fragments) inside multipart/alternative. This happens when users insert images
    # between paragraphs - Apple Mail creates: HTML + image + HTML structure.
    # We need to process parts in order to preserve image positioning.
    def handle_apple_mail_edge_case
      chosen_part = @mail.parts.first
      nodes = []

      chosen_part.parts.each do |part|
        if part.content_type.start_with?("text/html")
          doc = Nokogiri::HTML(part.decoded)
          nodes << (doc.at_css("body")&.inner_html || part.decoded)
        elsif part.attachment? && media_attachment?(part)
          attachment = find_attachment_from_part(part)
          if attachment
            nodes << process_attachment(attachment)
            @processed_attachment_ids << attachment[:original].object_id
          end
        end
      end

      nodes.join("\n")
    end

    # Detects Apple Mail's RFC violation: multipart/alternative containing
    # multipart/mixed with multiple HTML fragments
    def apple_mail_multipart_mixed_in_alternative?
      return false unless @mail.mime_type == "multipart/alternative"

      chosen_part = @mail.parts.first
      return false unless chosen_part&.multipart? && chosen_part.mime_type == "multipart/mixed"

      html_parts = chosen_part.parts.select { |p| p.content_type.start_with?("text/html") }
      html_parts.size > 1
    end

    def sanitized_body
      @sanitized_body ||= sanitize(body, tags: %w[img], attributes: %w[src alt])
    end

    def store_attachments
      @attachments = media_attachments.map do |attachment|
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(attachment.body.to_s),
          filename: attachment.filename,
          content_type: attachment.content_type,
        )

        { original: attachment, blob: blob, url: Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: true) }
      end
    end

    def media_attachments
      @mail.attachments.select { |attachment| media_attachment?(attachment) }
    end

    def find_attachment_from_part(part)
      @attachments.find { |a| a[:original].object_id == part.object_id }
    end

    def media_attachment?(part)
      part.content_type.start_with?("image/", "video/", "audio/")
    end

    def process_unreferenced_attachments(html_content)
      attachment_html = ""
      @attachments.each do |attachment|
        # Skip if already processed inline (Apple Mail edge case)
        next if @processed_attachment_ids.include?(attachment[:original].object_id)

        # Skip if referenced by Content-Id in HTML
        content_id = attachment[:original].content_id&.gsub(/\A<|>\Z/, "")
        next if content_id.present? && html_content.include?(content_id)

        attachment_html += process_attachment(attachment)
      end
      attachment_html
    end

    def process_attachment(attachment)
      preview_html = attachment_preview_node(
        attachment[:blob],
        attachment[:url],
        attachment[:original]
      )
      preview_html || ""
    end
end
