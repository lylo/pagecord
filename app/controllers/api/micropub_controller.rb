class Api::MicropubController < Api::BaseController
  include RoutingHelper

  BLOB_URL_PATTERN = %r{/active_storage/blobs/(?:redirect|proxy)/([^/]+)/}.freeze

  skip_before_action :authenticate, :require_premium, only: :query
  before_action :advertise_micropub_endpoint, only: :query
  before_action :authenticate_source_query, only: :query, if: :source_query?

  rescue_from BadRequestError do |e|
    invalid_request e.message
  end

  def create
    case request_body[:action]
    when "update" then update_post
    when "delete" then delete_post
    when nil, "" then create_post
    else               invalid_request "Unsupported action"
    end
  end

  def query
    case params[:q]
    when nil, "", "config" then render json: config_response
    when "syndicate-to" then render json: syndicate_to_response
    when "source" then render json: source_response(find_post!)
    else               invalid_request "Unsupported query"
    end
  end

  private

    def request_body
      request.request_parameters
    end

    def allow_access_token_parameter?
      true
    end

    def unauthorized
      render json: { error: access_token_submitted? ? "insufficient_scope" : "unauthorized" }, status: :unauthorized
    end

    def access_token_submitted?
      request.authorization.present? || request.request_parameters[:access_token].present?
    end

    def source_query?
      params[:q] == "source"
    end

    def advertise_micropub_endpoint
      response.headers["Link"] = %(<#{micropub_endpoint_url}>; rel="micropub")
    end

    def authenticate_source_query
      authenticate
      require_premium if Current.blog
    end

    def config_response
      syndicate_to_response.merge(
        "media-endpoint" => "#{micropub_endpoint_url}/media",
        "post-status" => %w[published draft]
      )
    end

    def syndicate_to_response
      { "syndicate-to" => [] }
    end

    def create_post
      attrs = Micropub::PostParams.new(params).to_h
      validate_status! attrs
      attrs[:content] = resolve_blob_images(attrs[:content]) if attrs[:content]
      post = Current.blog.posts.create(attrs.merge(source: :api))

      if post.persisted?
        response.headers["Location"] = micropub_post_url(post)
        head :created
      else
        invalid_request post.errors.full_messages.first, status: :unprocessable_entity
      end
    end

    def update_post
      post = find_post!
      original_url = micropub_post_url(post)

      if post.update(unchanged_content_skipped(update_attributes(post), post))
        updated_url = micropub_post_url(post)
        response.headers["Location"] = updated_url if updated_url != original_url
        head updated_url != original_url ? :created : :ok
      else
        invalid_request post.errors.full_messages.first, status: :unprocessable_entity
      end
    end

    def delete_post
      find_post!.discard!
      head :ok
    end

    def update_attributes(post)
      attrs = Micropub::PostParams.new(request_body[:replace]).to_h
      validate_status! attrs
      attrs[:content] = resolve_blob_images(attrs[:content]) if attrs[:content]
      tag_list = updated_tag_list(post)
      attrs[:tag_list] = tag_list if tag_list
      attrs
    end

    def updated_tag_list(post)
      replace = property_values(:replace, :category)
      added = property_values(:add, :category)
      deleted = property_values(:delete, :category)
      return if replace.empty? && added.empty? && deleted.empty?

      ((replace.presence || post.tag_list) + added - deleted).uniq
    end

    def property_values(operation, property)
      values = request_body[operation]
      return [] unless values.respond_to?(:key?)

      Array(values[property])
    end

    def find_post!
      raise ActiveRecord::RecordNotFound unless post_url_belongs_to_blog?

      Current.blog.posts.kept.find_by!(slug: slug_from_url)
    end

    def micropub_post_url(post)
      post.draft? ? edit_app_post_url(post, host: Rails.application.config.x.domain) : post_url(post)
    end

    def slug_from_url
      path = requested_post_url.path.delete_prefix("/").chomp("/")
      path.delete_prefix("posts/")
    end

    def requested_post_url
      @requested_post_url ||= URI.parse(params[:url].to_s)
    rescue URI::InvalidURIError
      nil
    end

    def post_url_belongs_to_blog?
      blog_url_hosts.include?(requested_post_url&.host&.downcase)
    end

    def blog_url_hosts
      [
        "#{Current.blog.subdomain}.#{Rails.application.config.x.domain}",
        Current.blog.custom_domain
      ].compact_blank.map(&:downcase)
    end

    def source_response(post)
      selected = Array(params[:properties]).presence
      properties = source_properties(post)
      properties = properties.slice(*selected) if selected

      selected ? { properties: properties } : { type: [ "h-entry" ], properties: properties }
    end

    def source_properties(post)
      {
        "name" => [ post.title ].compact,
        "content" => [ source_content(post) ],
        "category" => post.tag_list,
        "post-status" => [ post.status ],
        "published" => [ post.published_at&.iso8601 ].compact,
        "mp-slug" => [ post.slug ]
      }.select { |_key, values| values.present? }
    end

    def source_content(post)
      html = post.content.body.to_html
      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      elements = doc.children.select(&:element?)

      if elements.one? && elements.first.name == "p" && elements.first.element_children.empty?
        elements.first.text
      else
        { html: html }
      end
    end

    # Micropub clients reference uploaded images by blob URL returned from the
    # media endpoint. Convert those <img> tags to Action Text attachments so the
    # blob remains associated with the saved post.
    def resolve_blob_images(html)
      return html unless html&.match?(BLOB_URL_PATTERN)

      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      doc.css("img").each do |img|
        next unless blob = blob_from_url(img["src"])

        node = img.parent&.name == "figure" ? img.parent : img
        node.replace attachment_preview_node(blob, img["src"], attributes: { caption: img["alt"] })
      end
      doc.to_html
    end

    def blob_from_url(url)
      signed_id = url.to_s[BLOB_URL_PATTERN, 1]
      ActiveStorage::Blob.find_signed(signed_id) if signed_id
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    def invalid_request(description, status: :bad_request)
      render json: { error: "invalid_request", error_description: description }, status: status
    end

    def validate_status!(attrs)
      return unless attrs[:status].present?
      return if Post.statuses.key?(attrs[:status])

      raise BadRequestError, "'#{attrs[:status]}' is not a valid status"
    end
end
