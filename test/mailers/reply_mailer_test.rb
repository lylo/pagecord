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
    assert_equal "Re: #{reply.post.title}", email.subject
    assert_match "Great post! Keep it up.", email.body.encoded
    assert_match "Rails mailers", email.body.encoded
  end

  test "formats multiline message correctly" do
    reply = post_replies(:test)
    email = ReplyMailer.with(reply: reply).new_reply

    # HTML version should use simple_format to create paragraph tags
    html_part = email.body.parts.find { |p| p.content_type =~ /text\/html/ }
    assert_match "<p>Great post! Keep it up.</p>", html_part.body.encoded
    assert_match "<p>I especially liked the section about Rails mailers.", html_part.body.encoded
    assert_match "<p>Thanks for sharing this with us!", html_part.body.encoded

    # Text version should preserve line breaks
    text_part = email.body.parts.find { |p| p.content_type =~ /text\/plain/ }
    assert_match "Great post! Keep it up.\r\n\r\nI especially liked", text_part.body.encoded
  end
end
