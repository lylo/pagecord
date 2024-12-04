class App::PostsController < AppController
  include Pagy::Backend

  def index
    @pagy, @posts =  pagy(Current.user.posts.order(published_at: :desc), limit: 10)
  end

  def new
    @post = Current.user.posts.build
  end

  def edit
    @post = Current.user.posts.find_by!(token: params[:id])

    prepare_content_for_trix
  end

  def create
    # FIXME remove merge
    post = Current.user.posts.build(post_params.merge(blog: Current.user.blog))
    if post.save
      redirect_to app_posts_path, notice: "Post was successfully created"
    else
      @post = post
      flash.now.alert = @post.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def update
    post = Current.user.posts.find_by!(token: params[:id])

    if post.update(post_params)
      redirect_to app_posts_path, notice: "Post was successfully updated"
    else
      @post = post
      flash.now.alert = @post.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    post = Current.user.posts.find_by!(token: params[:id])
    post.destroy!

    redirect_to app_posts_path, notice: "Post was successfully deleted"
  end

  private

    def post_params
      params.require(:post).permit(:title, :content, :published_at)
    end

    def prepare_content_for_trix
      # To pacify Trix, remove new line characters and substitue <p> tags with <br> tags
      @post.content = @post.content.to_s.gsub(/\n/, "")
      @post.content = Html::StripParagraphs.new.transform(@post.content.to_s)
    end
end
