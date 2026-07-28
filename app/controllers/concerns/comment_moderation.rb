# Shared by every controller that moderates comments in the app: the feature
# guards, the comment being acted on, the list behind it, and the way back out.
module CommentModeration
  extend ActiveSupport::Concern

  include Pagy::Method

  included do
    before_action :require_comments_feature, :ensure_comments_enabled
    helper_method :return_path
  end

  private

    # Nested routes carry :comment_id, the member routes carry :id.
    def load_comment
      @comment = @blog.comments.includes(:post, :replies).find(params[:comment_id] || params[:id])
    end

    # Pending is the work queue, so it stays whole however long it gets. Only the
    # approved archive is paged.
    def load_comment_collections(post = nil)
      @post = post
      scope = @post&.comments || @blog.comments

      # :replies because every row asks whether you've already replied
      @pending = scope.pending.chronologically.includes(:post, :replies)
      @pagy, @approved = pagy(
        # Last activity rather than when it arrived, so a thread you've just
        # approved or replied to is at the top where you can find it again.
        scope.approved.top_level.order(updated_at: :desc).includes(:post, :replies)
      )
    end

    # Re-renders the moderation list in place, staying on the post you were
    # filtered to if that's where the action came from.
    def refresh_moderation(notice)
      load_comment_collections(origin_post)
      flash.now[:notice] = notice
      render template: "app/comments/refresh", formats: :turbo_stream
    end

    # A comment lives at /app/comments/:id however you got there, so the list you
    # came from is carried in a param rather than guessed.
    def return_path(comment)
      origin_post_token?(comment) ? app_post_comments_path(params[:post]) : app_comments_path
    end

    def origin_post
      @comment && origin_post_token?(@comment) ? @comment.post : nil
    end

    def origin_post_token?(comment)
      params[:post] == comment.post.token
    end

    def require_comments_feature
      render_app_not_found unless current_features.enabled?(:comments)
    end

    def ensure_comments_enabled
      redirect_to app_settings_audience_index_path unless @blog.accepts_comments?
    end
end
