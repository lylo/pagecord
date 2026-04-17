class Api::MicropubController < Api::BaseController
  include RoutingHelper

  BLOB_URL_PATTERN = %r{/active_storage/blobs/(?:redirect|proxy)/([^/]+)/}.freeze

  def create
    case request_body[:action]
    when "update" then update_post
    when "delete" then delete_post
    else               create_post
    end
  end

  def query
    case params[:q]
    when "config" then render json: config_response
    when "source" then render json: source_properties(find_post!)
    else               head :bad_request
    end
  end

  private

    def request_body
      request.request_parameters
    end

    def config_response
      {
        "media-endpoint" => "#{micropub_endpoint_url}/media",
        "syndicate-to"   => [],
        "post-status"    => %w[published draft]
      }
    end

    def create_post
      attrs = Micropub::PostParams.new(params).to_h
      attrs[:content] = resolve_blob_images(attrs[:content]) if attrs[:content]
      post = Current.blog.posts.create(attrs.merge(source: :api))

      if post.persisted?
        response.headers["Location"] = post_url(post)
        head :created
      else
        render json: { error: post.errors.full_messages.first }, status: :unprocessable_entity
      end
    end

    def update_post
      post = find_post!

      if post.update(unchanged_content_skipped(update_attributes(post), post))
        head :ok
      else
        render json: { error: post.errors.full_messages.first }, status: :unprocessable_entity
      end
    end

    def delete_post
      find_post!.discard!
      head :ok
    end

    def update_attributes(post)
      attrs = (request_body[:replace] || {}).each_with_object({}) do |(prop, values), h|
        if attr = Micropub::PostParams::ATTRIBUTE_MAP[prop.to_s]
          h[attr] = Array(values).first
        end
      end
      if tags = updated_tag_list(post)
        attrs[:tag_list] = tags
      end
      attrs
    end

    def updated_tag_list(post)
      replace = Array(request_body.dig(:replace, :category))
      added   = Array(request_body.dig(:add,    :category))
      removed = Array(request_body.dig(:remove, :category))
      return if replace.empty? && added.empty? && removed.empty?

      ((replace.presence || post.tag_list) + added - removed).uniq
    end

    def find_post!
      Current.blog.posts.kept.find_by!(slug: slug_from_url)
    end

    def slug_from_url
      URI.parse(params[:url].to_s).path.delete_prefix("/").chomp("/")
    rescue URI::InvalidURIError
      nil
    end

    def source_properties(post)
      {
        type: [ "h-entry" ],
        properties: {
          name:          [ post.title ].compact,
          content:       [ { html: post.content.body.to_html } ],
          category:      post.tag_list,
          "post-status": [ post.status ],
          published:     [ post.published_at&.iso8601 ].compact,
          "mp-slug":     [ post.slug ]
        }
      }
    end

    # Micropub clients reference uploaded images by blob URL (returned from the
    # media endpoint). Convert those <img> tags to <action-text-attachment> nodes
    # so Action Text retains the blob association — otherwise the purge job will
    # orphan the blob.
    def resolve_blob_images(html)
      return html unless html&.match?(BLOB_URL_PATTERN)

      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      doc.css("img").each do |img|
        next unless blob = blob_from_url(img["src"])
        node = img.parent&.name == "figure" ? img.parent : img
        node.replace attachment_preview_node(blob, img["src"], attributes: { alt: img["alt"] })
      end
      doc.to_html
    end

    def blob_from_url(url)
      signed_id = url.to_s[BLOB_URL_PATTERN, 1]
      ActiveStorage::Blob.find_signed(signed_id) if signed_id
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end
end
