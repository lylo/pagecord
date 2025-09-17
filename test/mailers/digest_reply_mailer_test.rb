require "test_helper"

class DigestReplyMailerTest < ActionMailer::TestCase
  test "forward_reply sends email to blog owner with correct subject and body" do
    digest = post_digests(:one)
    blog_owner = digest.blog.user

    # Create a mock original mail
    original_mail = Mail.new do
      from "subscriber@example.com"
      subject "Thanks for the digest!"
      body "I really enjoyed your latest posts about Rails."
      content_type "text/plain"
    end

    email = DigestReplyMailer.with(
      digest: digest,
      original_mail: original_mail
    ).forward_reply

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ blog_owner.email ], email.to
    assert_equal "subscriber@example.com", email.from.first
    assert_equal "Re: #{digest.subject}", email.subject
    assert_equal "I really enjoyed your latest posts about Rails.", email.body.to_s
    assert_match(/text\/plain/, email.content_type)
  end

  test "forward_reply preserves HTML content type" do
    digest = post_digests(:one)

    original_mail = Mail.new do
      from "subscriber@example.com"
      subject "Thanks!"
      body "<p>Great <strong>content</strong>!</p>"
      content_type "text/html"
    end

    email = DigestReplyMailer.with(
      digest: digest,
      original_mail: original_mail
    ).forward_reply

    assert_match(/text\/html/, email.content_type)
    assert_equal "<p>Great <strong>content</strong>!</p>", email.body.to_s
  end

  test "forward_reply does not send if no from address" do
    digest = post_digests(:one)

    original_mail = Mail.new do
      from nil
      subject "Thanks!"
      body "Great content!"
    end

    assert_no_emails do
      DigestReplyMailer.with(
        digest: digest,
        original_mail: original_mail
      ).forward_reply.deliver_now
    end
  end

  test "forward_reply uses correct subject with digest date" do
    digest = post_digests(:one)
    digest.update!(created_at: Date.parse("2025-03-15"))

    original_mail = Mail.new do
      from "subscriber@example.com"
      subject "Original subject"
      body "Content here"
    end

    email = DigestReplyMailer.with(
      digest: digest,
      original_mail: original_mail
    ).forward_reply

    # Should reconstruct the original digest subject with the digest's creation date
    expected_subject = I18n.with_locale(digest.blog.locale) do
      I18n.t(
        "email_subscribers.mailers.weekly_digest.subject",
        blog_name: digest.blog.display_name,
        date: I18n.l(Date.parse("2025-03-15"), format: :post_date)
      )
    end

    assert_equal "Re: #{expected_subject}", email.subject
  end
end
