class App::Comments::ClosuresController < AppController
  include CommentModeration

  before_action :load_comment

  def create
    @comment.post.close_comments!
    redirect_to comment_path, notice: "Comments closed."
  end

  def destroy
    @comment.post.reopen_comments!
    redirect_to comment_path, notice: "Comments reopened."
  end
end
