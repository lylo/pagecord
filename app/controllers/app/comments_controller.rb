class App::CommentsController < AppController
  include Pagy::Method

  PAGE_SIZE = 25

  helper_method :return_path

  before_action :ensure_comments_enabled
  before_action :load_comment, only: [ :show, :update, :destroy ]

  # Pending is the work queue, so it stays whole however long it gets. Only the
  # published archive is paged.
  def index
    @post = scoped_post
    scope = @post&.comments || @blog.comments

    # :replies because every row asks whether you've already replied
    @pending = scope.pending.chronologically.includes(:post, :replies)
    @pagy, @approved = pagy(
      # Last activity rather than when it arrived, so a thread you've just
      # approved or replied to is at the top where you can find it again.
      scope.approved.top_level.order(updated_at: :desc).includes(:post, :replies),
      limit: PAGE_SIZE
    )
  end

  def show
  end

  def create
    parent = @blog.comments.approved.top_level.find(params[:parent_id])
    @comment = parent.build_author_reply(reply_message)

    if @comment.save
      redirect_to return_path(parent), notice: "Reply posted."
    else
      redirect_to app_comment_path(parent, post: params[:post]), alert: @comment.errors.full_messages.to_sentence
    end
  end

  # Approving and replying are one decision, so a reply can ride along. It's
  # built and validated first, so a rejected reply doesn't leave the comment
  # approved with nothing attached.
  def update
    reply = @comment.build_author_reply(reply_message) if reply_message.present?

    if reply&.invalid?
      redirect_to app_comment_path(@comment, post: params[:post]), alert: reply.errors.full_messages.to_sentence
      return
    end

    Post::Comment.transaction do
      @comment.approve!
      reply&.save!
    end

    redirect_to return_path(@comment), notice: reply ? "Comment approved and your reply posted." : "Comment approved."
  end

  # Deleting your reply frees you to write another, so go back to the comment
  # rather than all the way out to the list.
  def destroy
    parent = @comment.parent
    @comment.destroy!

    if parent
      redirect_to app_comment_path(parent, post: params[:post]), notice: "Reply deleted."
    else
      redirect_to return_path(@comment), notice: "Comment deleted."
    end
  end

  private

    # Overridden by App::Posts::CommentsController to scope to one post.
    def scoped_post
      nil
    end

    # A comment lives at /app/comments/:id however you got there, so the list you
    # came from is carried in a param rather than guessed.
    def return_path(comment)
      params[:post] == comment.post.token ? app_post_comments_path(params[:post]) : app_comments_path
    end

    def load_comment
      @comment = @blog.comments.includes(:post, :replies).find(params[:id])
    end

    def reply_message
      params.dig(:comment, :message)
    end

    def ensure_comments_enabled
      redirect_to app_settings_audience_index_path unless @blog.accepts_comments?
    end
end
