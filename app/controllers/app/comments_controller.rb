class App::CommentsController < AppController
  include CommentModeration

  before_action :load_comment, only: [ :show, :destroy ]

  def index
    load_comment_collections(scoped_post)
  end

  def show
  end

  def destroy
    @comment.destroy!

    respond_to do |format|
      format.turbo_stream { refresh_moderation "Comment deleted." }
      format.html { redirect_to return_path, notice: "Comment deleted." }
    end
  end

  private

    # /app/posts/:post_token/comments routes here too, scoped to that post.
    def scoped_post
      @blog.posts.find_by!(token: params[:post_token]) if params[:post_token]
    end
end
