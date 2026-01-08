class Admin::ModerationController < AdminController
  include Pagy::Backend

  def index
    @tab = params[:tab] || "content"

    case @tab
    when "content"
      load_content_moderation
    when "spam"
      load_spam_detection
    end
  end

  def show
    if params[:type] == "spam"
      @spam_detection = SpamDetection.includes(blog: :user).find(params[:id])
      @blog = @spam_detection.blog
      render :show_spam
    else
      @post = Post.with_discarded.includes(:content_moderation, blog: :user).find(params[:id])
    end
  end

  def dismiss
    @post = Post.with_discarded.find(params[:id])
    @post.undiscard if @post.discarded?
    @post.content_moderation&.update!(status: :clean)
    redirect_to admin_moderation_index_path, notice: "Post restored and marked as reviewed"
  end

  def discard
    @post = Post.find(params[:id])
    @post.discard!
    redirect_to admin_moderation_index_path, notice: "Post discarded"
  end

  def dismiss_spam
    @spam_detection = SpamDetection.find(params[:id])
    @spam_detection.update!(status: :clean, reviewed: true, reviewed_at: Time.current)
    redirect_to admin_moderation_index_path(tab: "spam"), notice: "Blog marked as clean"
  end

  def confirm_spam
    @spam_detection = SpamDetection.find(params[:id])
    @spam_detection.mark_as_reviewed!
    redirect_to admin_moderation_index_path(tab: "spam"), notice: "Spam confirmed"
  end

  private

    def load_content_moderation
      @pagy, @posts = pagy(
        Post.with_discarded
            .moderation_flagged
            .published
            .joins(blog: :user)
            .where(users: { discarded_at: nil })
            .includes(:content_moderation, blog: :user)
            .order("content_moderations.moderated_at DESC"),
        limit: 25
      )
      @pending_count = Post.moderation_pending.count
    end

    def load_spam_detection
      @pagy, @spam_detections = pagy(
        SpamDetection.needs_review
                     .joins(blog: :user)
                     .where(users: { discarded_at: nil })
                     .includes(blog: :user)
                     .order(detected_at: :desc),
        limit: 25
      )
      @total_unreviewed = SpamDetection.needs_review.count
    end
end
