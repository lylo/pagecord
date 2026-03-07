class DynamicVariable::PostsTag
  STYLES = %w[card stream].freeze
  PAGE_SIZES = { "card" => 20, "stream" => 10 }.freeze

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
    @style = @post_list_params.style
  end

  def render
    if @style.in?(STYLES)
      render_paginated
    else
      render_title_list
    end
  end

  private

    def render_title_list
      posts = @post_list_params.limit ? filtered_relation.limit(@post_list_params.limit) : filtered_relation.all
      @view.render(partial: "blogs/custom_tags/posts", locals: { posts: posts })
    end

    def render_paginated
      page_size = self.class.page_size_for(@style)
      posts = filtered_relation.limit(page_size + 1).to_a
      has_next = posts.size > page_size
      posts = posts.first(page_size) if has_next
      frame_id = SecureRandom.hex(4)

      @view.render(partial: "blogs/custom_tags/posts_#{@style}",
        locals: { posts: posts, has_next: has_next, frame_id: frame_id,
                  filter_params: @post_list_params.query_params })
    end

    def filtered_relation
      @blog.posts.visible
        .filtered_for_dynamic_variable(**@post_list_params.filter_args)
    end
end
