class App::Comments::ThreadsController < AppController
  before_action :require_comments_feature
  before_action :load_comment

  def update
    post = @comment.post
    post.comments_open? ? post.close_comments! : post.reopen_comments!

    redirect_to app_comment_path(@comment, post: params[:post]),
      notice: post.comments_open? ? "Comments reopened." : "Comments closed."
  end

  private

    def require_comments_feature
      render_app_not_found unless current_features.enabled?(:comments)
    end

    def load_comment
      @comment = @blog.comments.find(params[:comment_id])
    end
end
