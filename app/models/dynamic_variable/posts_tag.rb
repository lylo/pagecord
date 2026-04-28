class DynamicVariable::PostsTag
  STYLES = %w[card stream title gallery].freeze
  PAGE_SIZES = { "card" => 20, "stream" => 10, "title" => 100, "gallery" => 20 }.freeze
  DEFAULT_STYLE = "title"

  class << self
    def valid_style?(style)
      style.to_s.in?(STYLES)
    end

    def page_size_for(style)
      PAGE_SIZES.fetch(style.to_s)
    end

    def with_gallery_image(relation)
      relation.where(<<~SQL.squish)
        EXISTS (
          SELECT 1
          FROM active_storage_attachments open_graph_attachments
          INNER JOIN active_storage_blobs open_graph_blobs
            ON open_graph_blobs.id = open_graph_attachments.blob_id
          WHERE open_graph_attachments.record_type = 'Post'
            AND open_graph_attachments.record_id = posts.id
            AND open_graph_attachments.name = 'open_graph_image'
            AND open_graph_blobs.content_type LIKE 'image/%'
        )
        OR EXISTS (
          SELECT 1
          FROM action_text_rich_texts
          INNER JOIN active_storage_attachments content_attachments
            ON content_attachments.record_type = 'ActionText::RichText'
            AND content_attachments.record_id = action_text_rich_texts.id
          INNER JOIN active_storage_blobs content_blobs
            ON content_blobs.id = content_attachments.blob_id
          WHERE action_text_rich_texts.record_type = 'Post'
            AND action_text_rich_texts.record_id = posts.id
            AND action_text_rich_texts.name = 'content'
            AND content_blobs.content_type LIKE 'image/%'
        )
      SQL
    end
  end

  def initialize(blog:, view:, params_string:)
    @blog = blog
    @view = view
    @post_list_params = DynamicVariable::PostListParams.new(blog: @blog, params_string: params_string)
    style = @post_list_params.style.presence
    @style = style&.in?(STYLES) ? style : DEFAULT_STYLE
  end

  def render
    if @post_list_params.limit
      posts = filtered_relation.limit(@post_list_params.limit)
      has_next = false
    else
      posts = filtered_relation.limit(page_size + 1).to_a
      has_next = posts.size > page_size
      posts = posts.first(page_size) if has_next
    end

    @view.render(partial: "blogs/custom_tags/posts_#{@style}",
      locals: { posts: posts, has_next: has_next, frame_id: SecureRandom.hex(4),
                filter_params: @post_list_params.query_params })
  end

  private

    def page_size
      self.class.page_size_for(@style)
    end

    def filtered_relation
      relation = @blog.posts.visible
        .filtered_for_dynamic_variable(**@post_list_params.filter_args)

      relation = self.class.with_gallery_image(relation).with_attached_open_graph_image if @style == "gallery"
      relation.for_blog_render
    end
end
