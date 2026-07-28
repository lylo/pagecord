class App::Comments::ApprovalsController < AppController
  include CommentModeration

  before_action :load_comment

  def create
    reply = @comment.build_author_reply(reply_message) if reply_message.present?
    return reject(reply) if reply&.invalid?

    Post::Comment.transaction do
      @comment.approve!
      reply&.save!
    end

    notice = reply ? "Comment approved and your reply posted." : "Comment approved."

    respond_to do |format|
      format.turbo_stream { refresh_moderation notice }
      format.html { redirect_to return_path, notice: notice }
    end
  end

  private

    def reply_message
      params.dig(:comment, :message)
    end

    def reject(reply)
      error = reply.errors.full_messages.to_sentence

      respond_to do |format|
        format.turbo_stream { render_reply_error error }
        format.html { redirect_to comment_path, alert: error }
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
