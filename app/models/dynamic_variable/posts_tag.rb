class DynamicVariable::PostsTag
  STYLES = %w[card stream titles].freeze
  PAGE_SIZES = { "card" => 20, "stream" => 10, "titles" => 100 }.freeze
  DEFAULT_STYLE = "titles"

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
    @style = @post_list_params.style.presence || DEFAULT_STYLE
  end

  def render
    render_posts
  end

  private

    def render_posts
      page_size = @post_list_params.limit&.clamp(1, self.class.page_size_for(@style)) || self.class.page_size_for(@style)
      posts = filtered_relation.limit(page_size + 1).to_a
      has_next = !@post_list_params.limit && posts.size > page_size
      posts = posts.first(page_size) if posts.size > page_size

      @view.render(partial: "blogs/custom_tags/posts_#{@style}",
        locals: { posts: posts, has_next: has_next, frame_id: SecureRandom.hex(4),
                  filter_params: @post_list_params.query_params })
    end

    def filtered_relation
      @blog.posts.visible
        .filtered_for_dynamic_variable(**@post_list_params.filter_args)
    end
end
