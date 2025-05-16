class App::PostsController < AppController
  include Pagy::Backend

  def index
    @pagy, @posts =  pagy(Current.user.blog.posts.published.order(published_at: :desc), limit: 25)

    @drafts = Current.user.blog.posts.draft.order(updated_at: :desc)
  end

  def new
    @post = Current.user.blog.posts.build(published_at: Time.current)
  end

  def edit
    @post = Current.user.blog.posts.find_by!(token: params[:id])

    prepare_content_for_trix
  end

  def create
    post = Current.user.blog.posts.build(post_params)
    if post.save
      redirect_to app_posts_path, notice: "Post was successfully created"
    else
      @post = post
      flash.now.alert = @post.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def update
    post = Current.user.blog.posts.find_by!(token: params[:id])

    if post.update(post_params)
      redirect_to app_posts_path, notice: "Post was successfully updated"
    else
      @post = post
      flash.now.alert = @post.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    post = Current.user.blog.posts.find_by!(token: params[:id])
    post.destroy!

    redirect_to app_posts_path, notice: "Post was successfully deleted"
  end

  private

    def post_params
      status = params[:button] == "save_draft" ? :draft : :published

      params.require(:post).permit(:title, :content, :published_at, :canonical_url).merge(status: status)
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
end
