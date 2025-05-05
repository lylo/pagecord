class Posts::RepliesController < Blogs::BaseController
  include SpamPrevention

  before_action :load_post
  before_action :verify, only: [ :create ]

  def new
    @reply = @post.replies.new(subject: "Re: #{@post.display_title}")

    @form_token = encryptor.encrypt_and_sign({
      post_id: @post.id
    })
  end

  def create
    @reply = @post.replies.new(reply_params)

    if @reply.save
      ReplyMailer.with(reply: @reply).new_reply.deliver_later

      # FIXME. The existing routing defines post_path and there is a post_path method
      # defined in RoutingHelper. The routes and helpers need tidying up to avoid confusion.
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
      @post = @blog.posts.find_by!(token: params[:post_id])
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
