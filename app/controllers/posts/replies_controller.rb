class Posts::RepliesController < ApplicationController
  before_action :load_post

  def new
    @reply = Post::Reply.new(subject: "Re: #{@post.display_title}")
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
      @post = Post.find_by!(token: params[:post_id])
      @blog = @post.blog
    end
end
