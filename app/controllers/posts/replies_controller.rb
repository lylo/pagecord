class Posts::RepliesController < Blogs::BaseController
  include SpamPrevention

  rate_limit to: 3, within: 1.hour, only: [ :create ]

  skip_before_action :authenticate
  skip_forgery_protection # Cached pages have no session cookie for CSRF verification

  before_action :load_post
  before_action :verify, only: [ :create ]

  def new
    redirect_to view_context.post_path(@post) and return unless @blog.reply_by_email

    @reply = @post.replies.new(subject: "Re: #{@post.display_title}")

    @form_token = @post.signed_id(purpose: :reply_form)
  end

  def create
    @reply = @post.replies.new(reply_params)

    if @reply.save
      SendPostReplyJob.perform_later(@reply.id)

      redirect_to sent_post_replies_path(@post)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def sent
  end

  private

    def submitted_email
      params.dig(:reply, :email)
    end

    def reply_params
      params.require(:reply).permit(:name, :email, :subject, :message)
    end

    def load_post
      @post = @blog.posts.with_full_rich_text.includes(blog: :avatar_attachment).find_by!(token: params[:post_token])
    end

    def verify
      unless Post.find_signed(params[:form_token], purpose: :reply_form) == @post
        Rails.logger.warn "Reply form token / post mismatch. Request blocked."
        head :unprocessable_entity
      end
    end
end
