# Creating a closure closes comments on the post; destroying it reopens them.
class App::Comments::ClosuresController < AppController
  include CommentModeration

  before_action :load_comment

  # Closing removes nothing, so both actions return to the comment you were
  # reading rather than out to the list.
  def create
    @comment.post.close_comments!
    redirect_to comment_path, notice: "Comments closed."
  end

  def destroy
    @comment.post.reopen_comments!
    redirect_to comment_path, notice: "Comments reopened."
  end
end
