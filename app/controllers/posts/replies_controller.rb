class Posts::RepliesController < Blogs::BaseController
  include SpamPrevention

  skip_before_action :authenticate, :ip_reputation_check

  before_action :load_post
  before_action :verify, only: [ :create ]

  def new
    redirect_to view_context.post_path(@post) and return unless @blog.reply_by_email

    @reply = @post.replies.new(subject: "Re: #{@post.display_title}")

    @form_token = encryptor.encrypt_and_sign({
      post_id: @post.id
    })
  end

  def create
    @reply = @post.replies.new(reply_params)

    if @reply.save
      SendPostReplyJob.perform_later(@reply.id)

      redirect_to view_context.post_path(@post), notice: "Reply sent successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

    def reply_params
      params.require(:reply).permit(:name, :email, :subject, :message)
    end

    def load_post
      @post = @blog.posts.find_by!(token: params[:post_token])
    end

    def verify
      begin
        token_data = encryptor.decrypt_and_verify(params[:form_token])
        if token_data["post_id"] != @post.id
          raise "Form token / post_id mismatch"
        end
      rescue => e
        Rails.logger.warn("Reply spam check failed: #{e.message}")
        head :unprocessable_entity and return
      end
    end

    def encryptor
      key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base).generate_key("form-token", 32)
      ActiveSupport::MessageEncryptor.new(key)
    end
end
