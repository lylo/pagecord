class Mcp::Tool
  POST_PROPERTIES = {
    title: { type: "string" },
    content: { type: "string", description: "The post body in Markdown. Front matter is supported." },
    slug: { type: "string" },
    status: { type: "string", enum: %w[ draft published ] },
    tags: { type: "string", description: "Comma-separated tags" },
    published_at: { type: "string", description: "ISO 8601 timestamp. A future time schedules the post." }
  }.freeze

  class << self
    include RoutingHelper, Rails.application.routes.url_helpers

    attr_reader :description, :properties, :required, :annotations

    def describe(description, properties: {}, required: [], **annotations)
      @description = description
      @properties = properties
      @required = required
      @annotations = { read_only: false, **annotations }.transform_keys { "#{it.to_s.camelize(:lower)}Hint" }
    end

    def default_url_options
      Rails.application.config.action_controller.default_url_options
    end

    def tool_name
      name.demodulize.underscore
    end

    def definition
      title = tool_name.humanize
      { name: tool_name, title:, description:, inputSchema: { type: "object", properties:, required: }, annotations: annotations.merge(title:) }
    end

    def call(blog, arguments)
      arguments = arguments.slice(*properties.keys).reject { |_key, value| value.nil? || value.is_a?(Enumerable) }
      missing = required - arguments.keys

      missing.any? ? failure("Missing required arguments: #{missing.join(", ")}") : content(perform(blog, **arguments))
    rescue ActiveRecord::RecordNotFound
      failure "Post not found"
    rescue ActiveRecord::RecordInvalid => e
      failure e.record.errors.full_messages.join("\n")
    rescue Api::BadRequestError, Api::ForbiddenError, Post::FrontMatter::InvalidError => e
      failure e.message
    end

    private

      def content(result)
        { content: [ { type: "text", text: result.to_json } ] }
      end

      def failure(message)
        { content: [ { type: "text", text: message } ], isError: true }
      end

      def find_post(blog, token)
        blog.posts.kept.find_by!(token:)
      end

      # Each image's attachment tag and blob, the blobs found in one query,
      # where Action Text's attachables resolves one blob per attachment.
      def image_attachments(fragment)
        nodes = fragment.find_all("action-text-attachment[sgid]").index_by do |node|
          SignedGlobalID.parse(node["sgid"], for: ActionText::Attachable::LOCATOR_NAME)&.model_id.to_i
        end
        ActiveStorage::Blob.where(id: nodes.keys).select(&:image?).map { [ nodes[it.id], it ] }
      end

      def post_attributes(arguments)
        params = ActionController::Parameters.new(arguments.merge(content_format: "markdown"))
        Api::PostParams.new(params, *POST_PROPERTIES.keys, :content_format).to_h
      end

      def summarize(post)
        {
          token: post.token,
          title: post.display_title,
          slug: post.slug,
          status: post.status,
          published_at: post.published_at,
          tags: post.tag_list,
          url: published_post_url(post)
        }
      end
  end
end
