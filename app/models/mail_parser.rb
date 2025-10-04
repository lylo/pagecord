class MailParser
  include Html::AttachmentPreview
  include ActionView::Helpers::SanitizeHelper

  def initialize(mail, process_attachments: true)
    @mail = mail

    @attachments = []
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
        html_parts = flatten_parts(@mail).select { |part| part.content_type.start_with?("text/html") }

        if html_parts.any?
          # If there are any HTML parts in the mail message, use these exclusively. Typically
          # there will only be one
          html_content = html_parts.map(&:decoded).join("\n")

          transformed_html = html_transform(html_content)

          # Process any attachments that are not referenced inline
          transformed_html << process_unreferenced_attachments(html_content)

          transformed_html
        else
          nodes = []

          # Multipart mail with no HTML parts, just plain text and images. Apple Mail defaults
          # to this, and the order matters.
          @mail.parts.each do |part|
            if part.text?
              nodes << plain_text_transform(part.decoded)
            elsif part.attachment? && media_attachment?(part)
              attachment = find_attachment_from_part(part)
              next unless attachment

              nodes << process_attachment(attachment)
            end
          end

          nodes.join("\n")
        end
      else
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

    def flatten_parts(mail_part)
      mail_part.parts.flat_map { |part| part.multipart? ? flatten_parts(part) : part }
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
