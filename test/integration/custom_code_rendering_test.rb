require "test_helper"

class CustomCodeRenderingTest < ActionDispatch::IntegrationTest
  HEAD_CODE = %(<script defer data-domain="joel.pagecord.com" src="https://plausible.io/js/script.js"></script>).freeze
  BODY_CODE = %(<div id="chat-widget"></div>).freeze

  setup do
    @blog = blogs(:joel)
    @blog.update!(custom_head_html: HEAD_CODE, custom_body_html: BODY_CODE)
    @post = posts(:one)
  end

  test "renders head code inside head and body code before the closing body tag" do
    get blog_post_url(subdomain: @blog.subdomain, slug: @post.slug)

    assert_response :success
    assert_includes response.body, HEAD_CODE
    assert_includes response.body, BODY_CODE
    assert response.body.index(HEAD_CODE) < response.body.index("</head>")
    assert response.body.index(BODY_CODE) > response.body.index("</main>")
    assert response.body.index(BODY_CODE) < response.body.index("</body>")
  end

  test "renders head code after the custom CSS so authors can override it" do
    @blog.update!(custom_css: "body { color: red; }")

    get blog_post_url(subdomain: @blog.subdomain, slug: @post.slug)

    assert response.body.index("color: red") < response.body.index(HEAD_CODE)
  end

  test "renders nothing when custom code is disabled" do
    @blog.update!(custom_code_enabled: false)

    get blog_post_url(subdomain: @blog.subdomain, slug: @post.slug)

    assert_response :success
    assert_not_includes response.body, HEAD_CODE
    assert_not_includes response.body, BODY_CODE
  end

  test "renders nothing when the subscription has lapsed" do
    @blog.user.subscription.destroy!

    get blog_post_url(subdomain: @blog.subdomain, slug: @post.slug)

    assert_response :success
    assert_not_includes response.body, HEAD_CODE
    assert_not_includes response.body, BODY_CODE
  end

  test "does not leak into the RSS feed" do
    get blog_feed_xml_url(subdomain: @blog.subdomain)

    assert_response :success
    assert_not_includes response.body, "plausible.io"
    assert_not_includes response.body, "chat-widget"
  end

  test "does not leak into the sitemap" do
    get blog_sitemap_url(subdomain: @blog.subdomain)

    assert_response :success
    assert_not_includes response.body, "plausible.io"
    assert_not_includes response.body, "chat-widget"
  end

  test "does not leak into post newsletters" do
    email = PostDigestMailer.with(subscriber: email_subscribers(:one), digest: post_digests(:one)).weekly_digest
    email.deliver_now

    body = ActionMailer::Base.deliveries.last.body.to_s
    assert_not_includes body, "plausible.io"
    assert_not_includes body, "chat-widget"
  end
end
