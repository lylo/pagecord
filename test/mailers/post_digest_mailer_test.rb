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

    assert_equal [ "digest@newsletters.pagecord.com" ], email.from
    assert_equal "\"#{blog.display_name}\" <digest@newsletters.pagecord.com>", email.header["from"].to_s
    assert_equal [ email_subscriber.email ], email.to
    assert_match blog.display_name, email.subject
  end

  test "digest email includes subscriber token header for bounce tracking" do
    email_subscriber = email_subscribers(:one)
    email = PostDigestMailer.with(subscriber: email_subscriber, digest: post_digests(:one)).weekly_digest

    assert_equal email_subscriber.token, email.header["X-PM-Metadata-SubscriberToken"].to_s
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
