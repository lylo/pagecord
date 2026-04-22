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

  test "digest email unwraps image attachments" do
    email_subscriber = email_subscribers(:one)
    post = create_post_with_attachment(
      blog: blogs(:joel),
      title: "Digest image post",
      caption: "Digest caption"
    )
    post_digests(:one).digest_posts.create!(post: post)

    email = PostDigestMailer.with(subscriber: email_subscriber, digest: post_digests(:one)).weekly_digest

    assert_includes email.body.encoded, "<figure"
    assert_includes email.body.encoded, "<img"
    assert_includes email.body.encoded, "Digest caption"
    assert_not_includes email.body.encoded, "action-text-attachment"
  end

  test "individual email renders correctly with post title as subject" do
    blog = blogs(:joel)
    email_subscriber = email_subscribers(:one)
    post = posts(:one)

    digest = PostDigest.create!(blog: blog, kind: :individual)
    digest.digest_posts.create!(post: post)

    email = PostDigestMailer.with(subscriber: email_subscriber, digest: digest).individual

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "digest@newsletters.pagecord.com" ], email.from
    assert_equal [ email_subscriber.email ], email.to
    assert_equal post.title, email.subject
  end

  test "individual email uses fallback subject when post has no title" do
    blog = blogs(:joel)
    email_subscriber = email_subscribers(:one)
    post = posts(:joel_titleless)

    digest = PostDigest.create!(blog: blog, kind: :individual)
    digest.digest_posts.create!(post: post)

    email = PostDigestMailer.with(subscriber: email_subscriber, digest: digest).individual

    assert_match blog.display_name, email.subject
  end

  test "individual email unwraps image attachments" do
    blog = blogs(:joel)
    email_subscriber = email_subscribers(:one)
    post = create_post_with_attachment(
      blog: blog,
      title: "Individual image post",
      caption: "Individual caption"
    )

    digest = PostDigest.create!(blog: blog, kind: :individual)
    digest.digest_posts.create!(post: post)

    email = PostDigestMailer.with(subscriber: email_subscriber, digest: digest).individual

    assert_includes email.body.encoded, "<figure"
    assert_includes email.body.encoded, "<img"
    assert_includes email.body.encoded, "Individual caption"
    assert_not_includes email.body.encoded, "action-text-attachment"
  end

  test "individual email includes unsubscribe footer" do
    blog = blogs(:joel)
    email_subscriber = email_subscribers(:one)
    post = posts(:one)

    digest = PostDigest.create!(blog: blog, kind: :individual)
    digest.digest_posts.create!(post: post)

    email = PostDigestMailer.with(subscriber: email_subscriber, digest: digest).individual

    assert_match "Unsubscribe", email.body.encoded
  end

  test "individual email includes broadcast headers" do
    email_subscriber = email_subscribers(:one)
    post = posts(:one)

    digest = PostDigest.create!(blog: blogs(:joel), kind: :individual)
    digest.digest_posts.create!(post: post)

    email = PostDigestMailer.with(subscriber: email_subscriber, digest: digest).individual

    assert_equal email_subscriber.token, email.header["X-PM-Metadata-SubscriberToken"].to_s
    assert_equal "broadcast", email.header["X-PM-Message-Stream"].to_s
  end

  test "test_individual sends to specified email with test subject prefix" do
    post = posts(:one)

    email = PostDigestMailer.with(post: post, email: "test@example.com").test_individual

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "test@example.com" ], email.to
    assert_equal "[Test] #{post.title}", email.subject
    assert_equal [ "digest@newsletters.pagecord.com" ], email.from
  end

  test "test_individual has no broadcast headers" do
    post = posts(:one)

    email = PostDigestMailer.with(post: post, email: "test@example.com").test_individual

    assert_nil email.header["X-PM-Metadata-SubscriberToken"].presence
    assert_nil email.header["X-PM-Message-Stream"].presence
    assert_nil email.header["List-Unsubscribe"].presence
  end

  test "test_individual omits unsubscribe footer" do
    post = posts(:one)

    email = PostDigestMailer.with(post: post, email: "test@example.com").test_individual

    assert_no_match "Unsubscribe", email.body.encoded
  end

  private

    def create_post_with_attachment(blog:, title:, caption:)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file_fixture("space.jpg").open,
        filename: "space.jpg",
        content_type: "image/jpeg"
      )

      blog.posts.create!(
        title: title,
        content: %(<p>Hello</p><action-text-attachment sgid="#{blob.attachable_sgid}" caption="#{caption}"></action-text-attachment>),
        status: :published,
        published_at: 30.minutes.ago
      )
    end
end
