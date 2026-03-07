class DynamicVariable::PostsTag
  include DynamicVariable::Params

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
    @params = parse_params(params_string)
    @style = @params[:style].to_s
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
      posts = @params[:limit] ? filtered_relation.limit(@params[:limit]) : filtered_relation.all
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
                  filter_params: filter_query_params })
    end

    def filtered_relation
      @blog.posts.visible
        .filtered_for_dynamic_variable(**filter_args)
    end

    def filter_args
      {}.tap do |args|
        args[:tag] = @params[:tag] if @params[:tag]
        args[:without_tag] = @params[:without_tag] if @params[:without_tag]
        args[:title] = @params[:title] if @params.key?(:title)
        args[:emailed] = @params[:emailed] if @params.key?(:emailed)
        args[:lang] = @params[:lang] if @params[:lang]
        args[:year] = @params[:year] if @params[:year]
        args[:sort] = @params[:sort] if @params[:sort]
        args[:blog_locale] = @blog.locale if @params[:lang]
      end
    end

    def filter_query_params
      {}.tap do |qp|
        qp[:tag] = Array(@params[:tag]).join(",") if @params[:tag]
        qp[:without_tag] = Array(@params[:without_tag]).join(",") if @params[:without_tag]
        qp[:title] = @params[:title].to_s if @params.key?(:title)
        qp[:emailed] = @params[:emailed].to_s if @params.key?(:emailed)
        qp[:lang] = @params[:lang] if @params[:lang]
        qp[:year] = @params[:year] if @params[:year]
        qp[:sort] = @params[:sort] if @params[:sort]
      end
    end
end
