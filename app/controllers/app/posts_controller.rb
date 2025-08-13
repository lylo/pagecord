class App::PostsController < AppController
  include Pagy::Backend

  rescue_from Pagy::OverflowError, with: :redirect_to_first_page

  def index
    posts_query = Current.user.blog.posts.published.order(published_at: :desc)
    drafts_query = Current.user.blog.posts.draft.order(updated_at: :desc)

    @search_term = params[:search]
    if @search_term.present?
      posts_query = posts_query.search_by_title_and_content(@search_term)
      drafts_query = drafts_query.search_by_title_and_content(@search_term)
    end

    @pagy, @posts = pagy(posts_query, limit: 25)
    @drafts = @pagy.page == 1 ? drafts_query : []
  end

  def new
    @post = Current.user.blog.posts.build(published_at: Time.current)
  end

  def edit
    @post = Current.user.blog.posts.find_by!(token: params[:token])

    session[:return_to_page] = params[:page] if params[:page].present?

    prepare_content_for_trix
  end

  def create
    post = Current.user.blog.posts.build(post_params)
    if post.save
      redirect_to app_posts_path, notice: "Post was successfully created"
    else
      @post = post
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @post = Current.user.blog.posts.find_by!(token: params[:token])

    if @post.update(post_params)
      page = session.delete(:return_to_page)
      options = page.present? ? { page: page } : {}

      redirect_to app_posts_path(options), notice: "Post was successfully updated"
    else
      prepare_content_for_trix
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    post = Current.user.blog.posts.find_by!(token: params[:token])
    post.destroy!

    redirect_to app_posts_path, notice: "Post was successfully deleted"
  end

  private
    def post_params
      status = params[:button] == "save_draft" ? :draft : :published

      params.require(:post).permit(:title, :content, :slug, :published_at, :canonical_url, :tags_string, :hidden).merge(status: status)
    end

    # HTML from inbound email doesn't often play nicely with Trix
    # This method performs some tweaks to try and help.
    def prepare_content_for_trix
      # Remove all newlines except for within <pre> blocks
      @post.content.to_s.gsub(/(<pre[\s\S]*?<\/pre>)|[\r\n]+/, '\1')

      # remove whitespace between tags (Trix seems to add a <br> tag in some cases)
      @post.content = @post.content.to_s.gsub(/>\s+</, "><")

      # remove paragraph tags
      @post.content = Html::StripParagraphs.new.transform(@post.content.to_s)
    end

    def redirect_to_first_page
      redirect_to app_posts_path
    end
end
