class Blogs::EmbeddedPostsController < Blogs::BaseController
  include Pagy::Method

  def self._prefixes
    super + [ "blogs/posts" ]
  end

  rescue_from Pagy::RangeError, with: :head_gone

  def index
    @style = params[:style]
    relation = @blog.posts.visible.apply_filters(**filter_params).order(published_at: :desc)
    @pagy, @posts = pagy(relation, limit: DynamicVariable::PostsTag::PAGE_SIZES.fetch(@style, 20))
    @frame_id = params[:frame_id]
    set_blog_cache_headers
    render layout: false
  end

  private

    def filter_params
      {}.tap do |fp|
        fp[:tag] = params[:tag].split(",").map(&:strip) if params[:tag]
        fp[:without_tag] = params[:without_tag].split(",").map(&:strip) if params[:without_tag]
        fp[:title] = params[:title] if params[:title]
        fp[:emailed] = params[:emailed] if params[:emailed]
        fp[:lang] = params[:lang] if params[:lang]
        fp[:blog_locale] = @blog.locale if params[:lang]
      end
    end

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
