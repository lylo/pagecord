class ReplyMailerPreview < ActionMailer::Preview
  def new_reply
    reply = Post::Reply.first
    ReplyMailer.with(reply: reply).new_reply
  end
end
