class App::PostsController < AppController
  include Pagy::Backend

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

    clean_content(@post)

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
      clean_content(@post)
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

    def clean_content(post)
      original_content = post.content.body&.to_html
      return if original_content.blank?

      if current_features.enabled?(:lexxy)
        # Only clean if content has old div structure but no paragraph tags
        has_divs = original_content.include?("<div>")
        has_paragraphs = original_content.include?("<p>")
        nil if !has_divs || has_paragraphs

        # Remove divs that are visually empty (only contain spaces, &nbsp;, or <br>)
        cleaned_content = original_content.gsub(/<div>(?:\s|&nbsp;|<br\s*\/?>)*<\/div>/i, "")
        if cleaned_content != original_content
          post.content = cleaned_content
        end
      else
        cleaned_content = Html::StripParagraphs.new.transform(original_content)

        # Replace <h2>, <h3>, <h4> with <h1>
        cleaned_content = cleaned_content.gsub(/<\/?h[2-4]>/i) { |tag| tag.sub(/h[2-4]/i, "h1") }

        # Remove all newlines except for within <pre> blocks
        cleaned_content = cleaned_content.gsub(/(<pre[\s\S]*?<\/pre>)|[\r\n]+/, '\1')

        # remove whitespace between tags (Trix seems to add a <br> tag in some cases)
        post.content = cleaned_content.gsub(/>\s+</, "><")
      end
    end

    def redirect_to_first_page
      redirect_to app_posts_path
    end
end
