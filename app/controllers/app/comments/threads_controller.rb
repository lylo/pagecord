class App::Comments::ThreadsController < AppController
  before_action :load_comment

  # Closing doesn't remove anything, so stay on the comment you were reading
  # rather than dropping back to the list.
  def update
    post = @comment.post
    post.comments_open? ? post.close_comments! : post.reopen_comments!

    redirect_to app_comment_path(@comment, post: params[:post]),
      notice: post.comments_open? ? "Comments reopened." : "Comments closed."
  end

  private

    def load_comment
      @comment = @blog.comments.find(params[:comment_id])
    end
end
