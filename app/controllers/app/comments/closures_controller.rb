# Creating a closure closes comments on the post; destroying it reopens them.
class App::Comments::ClosuresController < AppController
  include CommentModeration

  before_action :load_comment

  def create
    @comment.post.close_comments!
    redirect_to_comment "Comments closed."
  end

  def destroy
    @comment.post.reopen_comments!
    redirect_to_comment "Comments reopened."
  end

  private

    # Closing removes nothing, so return to the comment you were reading,
    # carrying the list origin as every other action on that page does.
    def redirect_to_comment(notice)
      redirect_to app_comment_path(@comment, post: params[:post]), notice: notice
    end
end
