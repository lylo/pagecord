class MailParser
  include Html::AttachmentPreview
  include ActionView::Helpers::SanitizeHelper

  def initialize(mail, process_attachments: true)
    @mail = mail
    @processed_attachment_ids = Set.new
    @attachments = []

    build_attachments if process_attachments

    @extract_tags = Html::ExtractTags.new

    @html_pipeline = [
      Html::BodyExtraction.new,
      Html::MonospaceDetection.new,
      Html::ImageUnfurl.new,
      Html::InlineAttachments.new(@attachments),
      @extract_tags,
      Html::Sanitize.new
    ].freeze

    @plain_text_pipeline = [
      Html::PlainTextToHtml.new,
      @extract_tags,
      Html::ImageUnfurl.new
    ].freeze
  end

  def subject
    @subject ||= @mail.subject&.strip
  end

  def body
    @body ||= parse_body
  end

  def attachments
    @attachments.map { |attachment| attachment[:blob] }
  end

  def has_attachments?
    !attachments.empty?
  end

  def tags
    body # ensure parsing
    Array(@extract_tags&.tags)
  end

  def blank?
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
      html = ensure_utf8(html)
      pipeline.reduce(html) { |content, step| step.transform(content) }
    end

    def ensure_utf8(html)
      charset = @mail.charset&.downcase
      return html if charset.blank? || charset == "utf-8"

      Rails.logger.info "Converting mail from #{charset} to UTF-8"
      html.encode("UTF-8", charset, invalid: :replace, undef: :replace, replace: "")
    end

    def parse_body
      if @mail.multipart?
        parse_multipart_body
      else
        parse_singlepart_body
      end
    end

    def parse_multipart_body
      # Handle different multipart structures:
      # - multipart/mixed: Attachments interspersed with content (text → image → text)
      #   Must process all parts sequentially since @mail.text_part only returns first part
      # - multipart/alternative: Multiple representations (HTML + plain text), prefer HTML
      # - multipart/related: HTML with inline images referenced by Content-ID

      case
      when @mail.mime_type == "multipart/mixed"
        parse_mixed_parts
      when @mail.html_part
        html = collect_html_content
        html_transform(html) + append_unreferenced_attachments(html)
      when @mail.text_part
        text = plain_text_transform(@mail.text_part.decoded)
        text + append_unreferenced_attachments(text)
      else
        parse_mixed_parts
      end
    end

    def parse_singlepart_body
      case @mail.content_type
      when /text\/plain/ then plain_text_transform(@mail.decoded)
      when /text\/html/  then html_transform(@mail.decoded)
      else raise "Unknown content type #{@mail.content_type}"
      end
    end

    def parse_mixed_parts
      @mail.parts.filter_map do |part|
        if part.multipart?
          # Handle nested multipart parts (e.g., multipart/alternative inside multipart/mixed)
          parse_multipart_part(part)
        elsif part.text?
          plain_text_transform(part.decoded)
        elsif part.attachment? && media_attachment?(part)
          attachment = find_attachment_from_part(part)
          process_attachment(attachment) if attachment
        end
      end.join("\n")
    end

    def parse_multipart_part(part)
      # Handle nested multipart structures (e.g., multipart/alternative)
      # Note: Don't append unreferenced attachments here - the parent parse_mixed_parts
      # loop will handle attachments directly to avoid duplication
      if part.html_part
        html = part.html_part.decoded
        html_transform(html)
      elsif part.text_part
        text = part.text_part.decoded
        plain_text_transform(text)
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
            @processed_attachment_ids << attachment_id(attachment)
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

    def build_attachments
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
      @attachments&.find { |a| a[:original].object_id == part.object_id }
    end

    def media_attachment?(part)
      part.content_type.start_with?("image/", "video/", "audio/")
    end

    def append_unreferenced_attachments(html_content)
      attachment_html = ""
      @attachments.each do |attachment|
        # Skip if already processed inline (Apple Mail edge case)
        next if @processed_attachment_ids.include?(attachment_id(attachment))

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

    def attachment_id(attachment)
      attachment[:original].object_id
    end
end
