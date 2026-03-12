class Api::BaseController < ActionController::API
  class BadRequestError < StandardError; end

  include ActionController::HttpAuthentication::Token::ControllerMethods
  include Html::AttachmentPreview

  wrap_parameters false

  before_action :authenticate
  before_action :require_premium
  before_action :require_api_enabled

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Not found" }, status: :not_found
  end

  rescue_from BadRequestError do |e|
    render json: { error: e.message }, status: :bad_request
  end

  rescue_from Post::FrontMatter::InvalidError do |e|
    render json: { error: "Invalid front matter: #{e.message}" }, status: :unprocessable_entity
  end

  rescue_from Pagy::RangeError do
    render json: { error: "Page out of range" }, status: :bad_request
  end

  rate_limit to: 60, within: 1.minute, by: -> { Current.blog&.id || request.remote_ip }, with: :rate_limit_reached

  private

    def authenticate
      authenticate_with_http_token do |token, _options|
        Current.blog = Blog.find_by_api_key(token)
      end

      render json: { error: "Unauthorized" }, status: :unauthorized unless Current.blog
    end

    def require_premium
      unless Current.blog.user.has_premium_access?
        render json: { error: "API access requires a premium subscription" }, status: :forbidden
      end
    end

    def require_api_enabled
      unless Current.blog.features.include?("api")
        render json: { error: "API access is not enabled for this blog" }, status: :forbidden
      end
    end

    def rate_limit_reached
      render json: { error: "Rate limit exceeded" }, status: :too_many_requests
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
    def enrich_attachments(html)
      enriched_html = ActionText::Fragment.wrap(html).replace(ActionText::Attachment.tag_name) do |node|
        blob = ActiveStorage::Blob.from_attachable_sgid(node["sgid"].presence || raise(BadRequestError, "Attachment sgid is required"))

        ActionText::Fragment.wrap(
          attachment_preview_node(
            blob,
            Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: true),
            attributes: attachment_preview_attributes_from(node)
          )
        ).to_html.then { |attachment_html| Nokogiri::HTML::DocumentFragment.parse(attachment_html).children.first }
      rescue ActiveRecord::RecordNotFound, ActiveSupport::MessageVerifier::InvalidSignature
        raise BadRequestError, "Attachment sgid must reference an ActiveStorage::Blob"
      end.to_html

      unwrap_attachment_paragraphs(enriched_html)
    end

    def permitted_content_params(*attributes, except_token: true)
      permitted = permitted_params(*attributes, except_token: except_token)
      permitted[:tags_string] = permitted.delete(:tags) if permitted.key?(:tags)

      render_markdown_content(permitted)
      validate_status_param(permitted)
      enrich_attachment_content(permitted)

      permitted
    end

    def set_pagination_headers(pagy)
      response.headers.merge!(pagy.headers_hash(headers_map: { page: nil, limit: nil, count: "X-Total-Count", pages: nil }))
    end

    def attachment_preview_attributes_from(node)
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

    def permitted_params(*attributes, except_token: true)
      source_params = except_token ? params.except(:token) : params
      source_params.permit(*attributes)
    end

    def render_markdown_content(permitted)
      return unless permitted.delete(:content_format) == "markdown"
      return unless permitted[:content].present?

      attributes, html = Post::Markdown.render(permitted[:content])
      attributes.each { |key, value| permitted[key] ||= value }
      permitted[:content] = html
    end

    def enrich_attachment_content(permitted)
      return unless permitted[:content]&.include?("<action-text-attachment")

      permitted[:content] = enrich_attachments(permitted[:content])
    end

    def validate_status_param(permitted)
      return unless permitted[:status].present?
      return if Post.statuses.key?(permitted[:status])

      raise BadRequestError, "'#{permitted[:status]}' is not a valid status"
    end

    def parse_iso8601_timestamp(value)
      Time.iso8601(value)
    rescue ArgumentError
      raise BadRequestError, "Invalid timestamp"
    end
end
