# Approving and replying are one decision, so a reply can ride along. It's built
# and validated first, so a rejected reply doesn't leave the comment approved
# with nothing attached.
class App::Comments::ApprovalsController < AppController
  include CommentModeration

  before_action :load_comment

  def create
    reply = @comment.build_author_reply(params.dig(:comment, :message)) if reply_message?
    return reject(reply) if reply&.invalid?

    Post::Comment.transaction do
      @comment.approve!
      reply&.save!
    end

    notice = reply ? "Comment approved and your reply posted." : "Comment approved."

    respond_to do |format|
      format.turbo_stream { refresh_moderation notice }
      format.html { redirect_to return_path(@comment), notice: notice }
    end
  end

  private

    def reply_message?
      params.dig(:comment, :message).present?
    end

    def reject(reply)
      error = reply.errors.full_messages.to_sentence

      respond_to do |format|
        format.turbo_stream { render_reply_error error }
        format.html { redirect_to app_comment_path(@comment, post: params[:post]), alert: error }
      end
    end

    def render_reply_error(error)
      render turbo_stream: turbo_stream.replace(
        @comment,
        partial: "app/comments/pending_comment",
        locals: { comment: @comment, reply_error: error }
      ), status: :unprocessable_entity
    end
end
