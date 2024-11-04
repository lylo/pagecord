class App::PostsController < AppController
  include Pagy::Backend

  before_action :requires_premium, only: [ :edit, :create, :update ]

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
    @post = Current.user.posts.find_by!(token: params[:id])

    prepare_content_for_trix
  end

  def create
    post = Current.user.posts.build(post_params)
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

    def requires_premium
      redirect to app_posts_path unless Current.user.is_premium?
    end

    def prepare_content_for_trix
      # To pacify Trix, remove new line characters and substitue <p> tags with <br> tags
      @post.content = @post.content.to_s.gsub(/\n/, "")
      @post.content = Html::StripParagraphs.new.transform(@post.content.to_s)
    end
end
