class Api::PostParams
  include Html::AttachmentPreview

  def initialize(params, *attributes, except_token: true)
    @params = params
    @attributes = attributes
    @except_token = except_token
  end

  def to_h
    permitted.tap do |attrs|
      attrs[:tags_string] = attrs.delete(:tags) if attrs.key?(:tags)

      render_markdown(attrs)
      validate_status(attrs)
      enrich_attachments(attrs)
    end.to_h
  end

  private

    attr_reader :params, :attributes, :except_token

    def permitted
      source = except_token ? params.except(:token) : params
      source.permit(*attributes)
    end

    def render_markdown(attrs)
      return unless attrs.delete(:content_format) == "markdown"
      return unless attrs[:content].present?

      front_matter, html = Post::Markdown.render(attrs[:content])
      front_matter.each { |key, value| attrs[key] ||= value }
      attrs[:content] = html
    end

    def validate_status(attrs)
      return unless attrs[:status].present?
      return if Post.statuses.key?(attrs[:status])

      raise Api::BadRequestError, "'#{attrs[:status]}' is not a valid status"
    end

    def enrich_attachments(attrs)
      return unless attrs[:content]&.include?("<action-text-attachment")

      attrs[:content] = unwrap_attachment_paragraphs(expand_attachments(attrs[:content]))
    end

    # Normalizes API-submitted attachments into canonical Action Text storage HTML.
    #
    # This keeps API-created content aligned with editor-created content by:
    # 1. Expanding bare SGID attachment tags into full blob-backed
    #    <action-text-attachment> nodes, preserving client-supplied attributes
    #    like caption and presentation.
    # 2. Removing Markdown-added <p> wrappers around standalone attachments, since
    #    canonical Action Text content stores those nodes at block level.
    #
    # We intentionally store <action-text-attachment> here. Public rendering, RSS,
    # and email may unwrap those wrappers later for display, but the API should
    # persist canonical Action Text markup.
    def expand_attachments(html)
      ActionText::Fragment.wrap(html).replace(ActionText::Attachment.tag_name) do |node|
        blob = ActiveStorage::Blob.from_attachable_sgid(node["sgid"].presence || raise(Api::BadRequestError, "Attachment sgid is required"))

        ActionText::Fragment.wrap(
          attachment_preview_node(
            blob,
            attachment_url(blob),
            attributes: preview_attributes_from(node)
          )
        ).to_html.then { |attachment_html| Nokogiri::HTML::DocumentFragment.parse(attachment_html).children.first }
      rescue ActiveRecord::RecordNotFound, ActiveSupport::MessageVerifier::InvalidSignature
        raise Api::BadRequestError, "Attachment sgid must reference an ActiveStorage::Blob"
      end.to_html
    end

    # The editor renders a previewable attachment as an <img> pointed at this url,
    # so a PDF needs its first-page representation here rather than the file
    # itself, which would just fail to load and drop back to a plain file chip.
    # Same size lexxy uses, so API-created attachments match editor-created ones.
    def attachment_url(blob)
      url_helpers = Rails.application.routes.url_helpers

      if blob.previewable?
        url_helpers.rails_representation_path(
          blob.preview(resize_to_limit: ActiveStorage::BlobWithPreviewUrl::PREVIEW_SIZE), only_path: true
        )
      else
        url_helpers.rails_blob_url(blob, only_path: true)
      end
    end

    def preview_attributes_from(node)
      {}.tap do |attributes|
        attributes[:caption] = node["caption"] if node["caption"].present?
        attributes[:presentation] = node["presentation"] if node["presentation"].present?
      end
    end

    # Markdown renders standalone attachment tags as <p><action-text-attachment>...</p>.
    # Unwrap those paragraphs so the stored HTML matches editor-created content.
    def unwrap_attachment_paragraphs(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      doc.css("p").each do |paragraph|
        children = paragraph.children.reject { |child| child.text? && child.text.strip.empty? }
        next if children.empty?
        next unless children.all? { |child| child.element? && child.name == ActionText::Attachment.tag_name }

        paragraph.replace(Nokogiri::HTML::DocumentFragment.parse(children.map(&:to_html).join))
      end

      doc.to_html
    end
end
