class Mcp::Tool < MCP::Tool
  POST_ATTRIBUTES = %i[ title content slug status tags published_at ].freeze

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

    def call(server_context:, **arguments)
      respond perform(server_context[:blog], **arguments.slice(*input_schema_value.to_h[:properties].keys))
    rescue ActiveRecord::RecordNotFound
      error "Post not found"
    rescue ActiveRecord::RecordInvalid => e
      error e.record.errors.full_messages.to_sentence
    rescue Api::BadRequestError, Post::FrontMatter::InvalidError => e
      error e.message
    end

    private

      def respond(data)
        MCP::Tool::Response.new([ { type: "text", text: data.to_json } ])
      end

      def error(message)
        MCP::Tool::Response.new([ { type: "text", text: message } ], error: true)
      end

      def find_post(blog, token)
        blog.posts.kept.find_by!(token:)
      end

      def post_attributes(arguments)
        params = ActionController::Parameters.new(arguments.merge(content_format: "markdown"))
        Api::PostParams.new(params, *POST_ATTRIBUTES, :content_format).to_h
      end

      def post_summary(post)
        {
          token: post.token,
          title: post.display_title,
          slug: post.slug,
          status: post.status,
          published_at: post.published_at,
          tags: post.tag_list,
          url: (post_url(post) if post.published?)
        }.compact
      end
  end
end
