class App::PostsController < AppController
  include Pagy::Backend

  def index
    @pagy, @posts =  pagy(Current.user.posts.order(published_at: :desc), items: 15)
  end

  def new
    if Rails.env.production?
      redirect_to app_posts_path
    else
      @post = Current.user.posts.build
    end
  end

  def edit
    @post = Current.user.posts.find(params[:id])

    # FIXME remove once all posts are stored as HTML
    if @post.html?
      @post.content = Html::StripParagraphs.new.transform(@post.content.to_s)
    else
      @post.content = Html::PlainTextToHtml.new.transform(@post.content.to_s)
    end
  end

  def create
    post = Current.user.posts.build(post_params.merge(html: true))
    if post.save
      redirect_to app_posts_path, notice: "Post was successfully created"
    else
      @post = post
      flash.now.alert = @post.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def update
    post = Current.user.posts.find(params[:id])
    if post.update(post_params)
      redirect_to app_posts_path, notice: "Post was successfully updated"
    else
      @post = post
      flash.now.alert = @post.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    post = Current.user.posts.find(params[:id])
    post.destroy!

    redirect_to app_posts_path, notice: "Post was successfully deleted"
  end

  private

    def post_params
      params.require(:post).permit(:title, :content)
    end
end
