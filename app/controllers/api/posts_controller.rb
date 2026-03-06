class Api::PostsController < Api::BaseController
  include Pagy::Method

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

    posts = posts.where("published_at >= ?", params[:published_after]) if params[:published_after]
    posts = posts.where("published_at <= ?", params[:published_before]) if params[:published_before]

    @pagy, @posts = pagy(posts.order(published_at: :desc))

    render json: {
      posts: @posts.map { |post| post_json(post) },
      pagination: pagination_json(@pagy)
    }
  end

  before_action :set_post, only: %i[show update destroy]

  def show
    render json: post_json(@post)
  end

  def create
    post = Current.blog.posts.build(post_params)

    if post.save
      render json: post_json(post), status: :created
    else
      render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @post.update(post_params)
      render json: post_json(@post)
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @post.discard!
    head :no_content
  end

  private

    def set_post
      @post = Current.blog.posts.kept.find_by!(token: params[:token])
    end

    def post_params
      permitted = params.permit(:title, :content, :slug, :published_at, :canonical_url, :tags_string, :hidden, :locale, :status, :content_format)

      if permitted.delete(:content_format) == "markdown" && permitted[:content].present?
        markdown = Redcarpet::Markdown.new(
          Redcarpet::Render::HTML,
          autolink: true, tables: true, fenced_code_blocks: true, strikethrough: true
        )
        permitted[:content] = markdown.render(permitted[:content])
      end

      permitted
    end

    def post_json(post)
      post.as_json(only: %i[token title slug status published_at canonical_url tag_list hidden locale created_at updated_at]).merge(
        content: post.content.to_s
      )
    end

    def pagination_json(pagy)
      { page: pagy.page, pages: pagy.pages, count: pagy.count }
    end
end
