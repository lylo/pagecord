# Creating a closure closes comments on the post; destroying it reopens them.
class App::Comments::ClosuresController < AppController
  before_action :require_comments_feature
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

    def require_comments_feature
      render_app_not_found unless current_features.enabled?(:comments)
    end

    def load_comment
      @comment = @blog.comments.find(params[:comment_id])
    end

    # Closing removes nothing, so return to the comment you were reading,
    # carrying the list origin as every other action on that page does.
    def redirect_to_comment(notice)
      redirect_to app_comment_path(@comment, post: params[:post]), notice: notice
    end
end
