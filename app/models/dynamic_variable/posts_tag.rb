class DynamicVariable::PostsTag
  STYLES = %w[card stream title].freeze
  PAGE_SIZES = { "card" => 20, "stream" => 10, "title" => 100 }.freeze
  DEFAULT_STYLE = "title"

  class << self
    def valid_style?(style)
      style.to_s.in?(STYLES)
    end

    def page_size_for(style)
      PAGE_SIZES.fetch(style.to_s)
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
      @blog.posts.visible
        .filtered_for_dynamic_variable(**@post_list_params.filter_args)
        .for_blog_render
    end
end
