class SendPostReplyJob < ApplicationJob
  queue_as :default

  def perform(reply_id)
    reply = Post::Reply.find_by(id: reply_id)
    return unless reply

    ReplyMailer.with(reply: reply).new_reply.deliver_now

    # Don't store the email for longer than is necessary
    reply.destroy!
  end
end
