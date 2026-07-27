class Posts::CommentsController < Blogs::BaseController
  include Pagy::Method

  before_action :require_comments_feature

  include SpamPrevention

  layout false # Responses are Turbo Frames, so the surrounding page is dead weight

  PAGE_SIZE = 20

  rate_limit to: 3, within: 1.hour, only: [ :create ]

  skip_before_action :authenticate
  skip_forgery_protection # Cached pages have no session cookie for CSRF verification

  before_action :load_post
  before_action :verify, only: [ :create ]

  # Deliberately never calls set_blog_cache_headers: the frame is fetched
  # separately so approved comments stay out of the edge cached post page.
  def index
    head :not_found and return unless @blog.accepts_comments? && @post.comments_visible?

    load_comments
  end

  def create
    head :not_found and return unless @blog.accepts_comments? && @post.comments_open?

    @comment = @post.comments.new(comment_params)
    @submitted = @comment.save
    CheckPostCommentJob.perform_later(@comment.id) if @submitted

    load_comments
    render :index, status: @submitted ? :ok : :unprocessable_entity
  end

  private

    def require_comments_feature
      head :not_found unless current_features.enabled?(:comments)
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
        @post.comments.approved.top_level.chronologically.includes(:replies),
        limit: PAGE_SIZE
      )
    end

    def verify
      unless Post.find_signed(params[:form_token], purpose: :comment_form) == @post
        Rails.logger.warn "Comment form token / post mismatch. Request blocked."
        head :unprocessable_entity
      end
    end

    # A rejected submission still has to leave a usable frame behind, and 422 is
    # the one non-2xx status Turbo reliably renders into a frame. Anything else
    # (403, 429, or the shared full-page error template) has no matching frame
    # in it, so the reader is left staring at "Content missing".
    #
    # The spam checks are registered when the concern is included, so they run
    # before load_post and we have to load it ourselves here.
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
