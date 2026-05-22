class Api::PostsController < Api::BaseController
  include Pagy::Method

  before_action :set_post, only: %i[show update destroy]

  def index
    posts = Current.blog.posts.kept

    case params[:status]
    when "draft"
      posts = posts.draft
    when "published"
      posts = posts.published
    else
      posts = posts.published.released
    end

    posts = posts.where("published_at >= ?", parse_iso8601_timestamp(params[:published_after])) if params[:published_after]
    posts = posts.where("published_at <= ?", parse_iso8601_timestamp(params[:published_before])) if params[:published_before]

    @pagy, @posts = pagy(posts.order(published_at: :desc))
    set_pagination_headers(@pagy)

    render json: @posts.map { |post| post_json(post) }
  end

  def show
    render json: post_json(@post)
  end

  def create
    post = Current.blog.posts.build(post_params.merge(source: :api))

    if post.save
      render json: post_json(post), status: :created
    else
      render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @post.update(unchanged_content_skipped(post_params, @post))
      render json: post_json(@post)
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if params[:permanent] == "true"
      @post.destroy!
    else
      @post.discard!
    end
    head :no_content
  end

  private

    def set_post
      @post = Current.blog.posts.kept.find_by!(token: params[:token])
    end

    def post_params
      permitted_content_params(:title, :content, :slug, :published_at, :canonical_url, :tags, :hidden, :locale, :status, :content_format)
    end

    def post_json(post)
      fields = %i[token title slug status published_at canonical_url tag_list hidden locale created_at updated_at]
      post.as_json(only: fields).merge(content: post.content.body.to_html)
    end
end
