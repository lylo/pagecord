# Replying to a comment that's already approved. Approving and replying at once
# is App::Comments::ApprovalsController's job.
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

  # Deleting your reply frees you to write another, so go back to the comment
  # rather than all the way out to the list.
  def destroy
    @comment.replies.find(params[:id]).destroy!

    redirect_to comment_path, notice: "Reply deleted."
  end

  private

    # Only an approved top-level comment can be replied to.
    def load_comment
      @comment = @blog.comments.approved.top_level.includes(:replies).find(params[:comment_id])
    end
end
