module CommentModeration
  extend ActiveSupport::Concern

  include Pagy::Method

  included do
    before_action :require_comments_feature, :ensure_comments_enabled
    helper_method :return_path
  end

  private

    def load_comment
      @comment = @blog.comments.includes(:post, :replies).find(params[:comment_id] || params[:id])
    end

    def load_comment_collections(post)
      @post = post
      scope = @post&.comments || @blog.comments

      # Loaded, not lazy: the view asks each list its size before rendering it.
      @pending = scope.pending.chronologically.includes(:post, :replies).load
      @pagy, @approved = pagy(
        scope.approved.top_level.order(updated_at: :desc).includes(:post, :replies)
      )
      @approved.load
    end

    def refresh_moderation(notice)
      load_comment_collections(origin_post)
      flash.now[:notice] = notice
      render template: "app/comments/refresh", formats: :turbo_stream
    end

    def return_path
      origin_post ? app_post_comments_path(origin_post) : app_comments_path
    end

    def comment_path
      app_comment_path(@comment, post: params[:post])
    end

    def origin_post
      @comment.post if @comment && params[:post] == @comment.post.token
    end

    def require_comments_feature
      render_app_not_found unless current_features.enabled?(:comments)
    end

    def ensure_comments_enabled
      redirect_to app_settings_audience_index_path unless @blog.accepts_comments?
    end
end
