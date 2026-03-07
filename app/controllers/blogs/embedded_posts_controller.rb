class Blogs::EmbeddedPostsController < Blogs::BaseController
  include Pagy::Method

  rate_limit to: 60, within: 1.minute

  def self._prefixes
    super + [ "blogs/posts" ]
  end

  rescue_from Pagy::RangeError, with: :head_gone

  def index
    post_list_params = DynamicVariable::PostListParams.new(blog: @blog, params: params)
    @style = post_list_params.style
    raise ActiveRecord::RecordNotFound unless DynamicVariable::PostsTag.valid_style?(@style)

    relation = @blog.posts.visible
      .filtered_for_dynamic_variable(**post_list_params.filter_args)
      .for_blog_render

    @pagy, @posts = pagy(relation, limit: DynamicVariable::PostsTag.page_size_for(@style))
    @frame_id = params[:frame_id].presence || SecureRandom.hex(4)
    set_blog_cache_headers
    render layout: false
  end

  private

    def head_gone
      head :gone
    end

    def set_blog_cache_headers
      return unless Rails.env.production? && ENV["CLOUDFLARE_ZONE_ID"].present? && ENV["CLOUDFLARE_API_TOKEN"].present?

      response.headers["Cache-Tag"] = @blog.subdomain
      request.session_options[:skip] = true
      expires_in 0, public: true, "s-maxage": 12.hours.to_i, "stale-while-revalidate": 1.hour.to_i
    end
end
