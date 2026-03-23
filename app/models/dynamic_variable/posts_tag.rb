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
    limit = @post_list_params.limit&.clamp(1, page_size) || page_size
    paginate = @post_list_params.limit.nil?
    posts = filtered_relation.limit(paginate ? limit + 1 : limit).to_a
    has_next = paginate && posts.size > limit
    posts = posts.first(limit) if has_next

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
    end
end
