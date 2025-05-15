require "test_helper"

class ReplyMailerTest < ActionMailer::TestCase
  test "new_reply email" do
    reply = post_replies(:test)
    email = ReplyMailer.with(reply: reply).new_reply

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "fred@example.com" ], email.reply_to
    assert_equal [ reply.post.blog.user.email ], email.to
    assert_equal "New reply to your post: #{reply.post.title}", email.subject
    assert_match reply.message, email.body.encoded
  end
end
