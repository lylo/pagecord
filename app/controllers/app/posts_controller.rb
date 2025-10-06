class App::PostsController < AppController
  include Pagy::Backend
  include EditorPreparation  # Add this line

  rescue_from Pagy::OverflowError, with: :redirect_to_first_page

  def index
    posts_query = Current.user.blog.posts.published.order(published_at: :desc)
    drafts_query = Current.user.blog.posts.draft.order(updated_at: :desc)

    @search_term = params[:search]
    if @search_term.present?
      if @search_term.match?(/^".*"$/)  # Starts and ends with quotes
        clean_query = @search_term.gsub(/^"|"$/, "")  # Remove quotes
        posts_query = posts_query.search_exact_phrase(clean_query)
        drafts_query = drafts_query.search_exact_phrase(clean_query)
      else
        posts_query = posts_query.search_by_title_and_content(@search_term)
        drafts_query = drafts_query.search_by_title_and_content(@search_term)
      end
    end

    @pagy, @posts = pagy(posts_query, limit: 25)
    @drafts = @pagy.page == 1 ? drafts_query.load : []
    @total_posts_count = Current.user.blog.posts.published.count
  end

  def new
    @post = Current.user.blog.posts.build(published_at: Time.current)
  end

  def edit
    @post = Current.user.blog.posts.find_by!(token: params[:token])

    prepare_content_for_editor(@post)

    session[:return_to_page] = params[:page] if params[:page].present?
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
      prepare_content_for_editor(@post)
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

    def redirect_to_first_page
      redirect_to app_posts_path
    end
end
