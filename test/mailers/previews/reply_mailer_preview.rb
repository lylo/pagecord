class ReplyMailerPreview < ActionMailer::Preview
  # Replies are destroyed the moment they're mailed, so there's never one to
  # find. Built here instead, as ContactMailerPreview does.
  def new_reply
    post = Blog.find_by(subdomain: "joel").posts.visible.first
    post.blog.locale = params[:locale] if params[:locale]

    reply = Post::Reply.new(
      post: post,
      name: "Jane Doe",
      email: "jane@example.com",
      subject: "Re: #{post.display_title}",
      message: "Great post! The bit about waiting for the light really resonated."
    )

    ReplyMailer.with(reply: reply).new_reply
  end
end
