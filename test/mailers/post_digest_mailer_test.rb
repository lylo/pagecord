require "test_helper"

class PostDigestMailerTest < ActionMailer::TestCase
  test "digest email renders correctly" do
    blog = blogs(:joel)
    email_subscriber = email_subscribers(:one)
    posts = [ posts(:one), posts(:two) ]

    email = PostDigestMailer.with(subscriber: email_subscriber, digest: post_digests(:one)).weekly_digest

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "no-reply@notifications.pagecord.com" ], email.from
    assert_equal "\"#{blog.display_name}\" <no-reply@notifications.pagecord.com>", email.header["from"].to_s
    assert_equal [ email_subscriber.email ], email.to
    # Just check that the subject contains the blog name
    assert_match blog.display_name, email.subject
  end

  test "digest email with custom blog domain" do
    blog = blogs(:joel)
    blog.update!(custom_domain: "custom.example.com")
    email_subscriber = email_subscribers(:one)
    posts = [ posts(:one) ]

    email = PostDigestMailer.with(subscriber: email_subscriber, digest: post_digests(:one)).weekly_digest

    assert_match "custom.example.com", email.body.encoded
  end
end
