class Posts::CommentsController < Blogs::BaseController
  include Pagy::Method

  before_action :require_comments_feature

  include SpamPrevention

  layout false # Responses are Turbo Frames, so the surrounding page is dead weight

  rate_limit to: 3, within: 1.hour, only: [ :create ]

  skip_before_action :authenticate
  skip_forgery_protection # Cached pages have no session cookie for CSRF verification

  before_action :load_post
  before_action :form_token_check, only: [ :create ]
  before_action :ensure_comments_visible, only: [ :index ]
  before_action :ensure_comments_open, only: [ :create ]

  def index
    load_comments
  end

  def create
    @comment = @post.comments.new(comment_params)
    CheckPostCommentJob.perform_later(@comment.id) if @comment.save

    load_comments
    render :index, status: @comment.persisted? ? :ok : :unprocessable_entity
  end

  private

    def require_comments_feature
      head :not_found unless current_features.enabled?(:comments)
    end

    def ensure_comments_visible
      head :not_found unless @blog.accepts_comments? && @post.comments_visible?
    end

    def ensure_comments_open
      head :not_found unless @blog.accepts_comments? && @post.comments_open?
    end

    def comment_params
      params.require(:comment).permit(:name, :link, :message)
    end

    def load_post
      @post = @blog.posts.kept.published.released.find_by!(token: params[:post_token])
    end

    def load_comments
      @comment ||= @post.comments.new
      @form_token = @post.signed_id(purpose: :comment_form)
      @pagy, @comments = pagy(
        @post.comments.approved.top_level.chronologically.includes(:replies)
      )
    end

    def signed_form_record
      @post
    end

    def form_token_purpose
      :comment_form
    end

    # 422 is the one non-2xx status Turbo renders back into a frame. load_post
    # is called here because the spam checks run before it.
    def reject_submission
      load_post
      @rejected = true
      load_comments
      render :index, status: :unprocessable_entity
    end

    def render_too_many_requests
      reject_submission
    end
end
