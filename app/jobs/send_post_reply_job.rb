class SendPostReplyJob < ApplicationJob
  queue_as :default

  def perform(reply_id)
    reply = Post::Reply.find_by(id: reply_id)
    return unless reply

    if spam?(reply)
      Rails.logger.info("[SendPostReplyJob] Spam detected, destroying reply #{reply.id}")
      reply.destroy!
      return
    end

    ReplyMailer.with(reply: reply).new_reply.deliver_now

    # Don't store the email for longer than is necessary
    reply.destroy!
  end

  private

    def spam?(reply)
      detector = MessageSpamDetector.new(
        name: reply.name,
        email: reply.email,
        message: reply.message
      )
      detector.detect
      detector.spam?
    rescue => e
      Rails.logger.error("[SendPostReplyJob] Spam check failed: #{e.message}")
      false
    end
end
