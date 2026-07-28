class App::Comments::RepliesController < AppController
  include CommentModeration

  before_action :load_comment

  def create
    @reply = @comment.build_author_reply(params.dig(:comment, :message))

    if @reply.save
      redirect_to return_path, notice: "Reply posted."
    else
      redirect_to comment_path, alert: @reply.errors.full_messages.to_sentence
    end
  end

  def destroy
    @comment.replies.find(params[:id]).destroy!

    redirect_to comment_path, notice: "Reply deleted."
  end

  private

    def load_comment
      @comment = @blog.comments.approved.top_level.includes(:replies).find(params[:comment_id])
    end
end
