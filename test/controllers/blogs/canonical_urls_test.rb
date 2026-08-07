require "test_helper"

class Blogs::CanonicalUrlsTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    @post = @blog.posts.visible.first

    host_subdomain! @blog.subdomain

    Rails.cache.clear
  end

  test "flat format renders at the bare slug" do
    get "/#{@post.slug}"

    assert_response :success
  end

  test "flat format redirects a prefixed posts path to the canonical post URL" do
    get "/posts/#{@post.slug}"

    assert_redirected_to "http://#{@blog.subdomain}.example.com/#{@post.slug}"
    assert_equal 301, @response.status
  end

  test "flat format redirects a prefixed posts path for pages" do
    page = posts(:about)

    get "/posts/#{page.slug}"

    assert_redirected_to "http://#{@blog.subdomain}.example.com/#{page.slug}"
    assert_equal 301, @response.status
  end

  test "prefix format renders under the folder and redirects the bare slug" do
    @blog.update!(post_url_format: "prefix", post_url_prefix: "notes")

    get "/notes/#{@post.slug}"
    assert_response :success

    get "/#{@post.slug}"
    assert_redirected_to "http://#{@blog.subdomain}.example.com/notes/#{@post.slug}"
    assert_equal 301, @response.status
  end

  test "prefix format redirects a stale folder name" do
    @blog.update!(post_url_format: "prefix", post_url_prefix: "articles")

    get "/notes/#{@post.slug}"

    assert_redirected_to "http://#{@blog.subdomain}.example.com/articles/#{@post.slug}"
    assert_equal 301, @response.status
  end

  test "prefix format renders the posts archive at the bare folder" do
    @blog.update!(post_url_format: "prefix", post_url_prefix: "notes")

    get "/notes"

    assert_response :success
    assert_template "blogs/posts/index"
  end

  test "prefix format redirects the posts archive to the folder, keeping filters" do
    @blog.update!(post_url_format: "prefix", post_url_prefix: "notes")

    get "/posts", params: { tag: "travel" }

    assert_redirected_to "http://#{@blog.subdomain}.example.com/notes?tag=travel"
    assert_equal 301, @response.status
  end

  test "prefix format points the posts navigation item at the folder" do
    @blog.update!(post_url_format: "prefix", post_url_prefix: "notes")

    assert_equal "/notes", PostsNavigationItem.new(blog: @blog).link_url
  end

  test "switching back to flat keeps old folder post links working" do
    @blog.update!(post_url_format: "prefix", post_url_prefix: "blogaroo")
    @blog.update!(post_url_format: "flat")

    get "/blogaroo/#{@post.slug}"
    assert_redirected_to "http://#{@blog.subdomain}.example.com/#{@post.slug}"
    assert_equal 301, @response.status

    get "/blogaroo"
    assert_response :not_found
  end

  test "prefix format leaves pages at the bare slug" do
    @blog.update!(post_url_format: "prefix", post_url_prefix: "notes")
    page = posts(:about)

    get "/#{page.slug}"
    assert_response :success

    get "/notes/#{page.slug}"
    assert_redirected_to "http://#{@blog.subdomain}.example.com/#{page.slug}"
    assert_equal 301, @response.status
  end

  test "dated format renders at the dated path and redirects the bare slug" do
    @blog.update!(post_url_format: "dated")
    dated_path = "/#{@post.published_at.strftime("%Y/%m/%d")}/#{@post.slug}"

    get dated_path
    assert_response :success

    get "/#{@post.slug}"
    assert_redirected_to "http://#{@blog.subdomain}.example.com#{dated_path}"
    assert_equal 301, @response.status
  end

  test "dated format redirects a wrong date to the right one" do
    @blog.update!(post_url_format: "dated")

    get "/1999/01/01/#{@post.slug}"

    assert_redirected_to "http://#{@blog.subdomain}.example.com/#{@post.published_at.strftime("%Y/%m/%d")}/#{@post.slug}"
    assert_equal 301, @response.status
  end

  test "sitemap and feed use the canonical format" do
    @blog.update!(post_url_format: "prefix", post_url_prefix: "notes")

    get "/sitemap.xml"
    assert_response :success
    assert_includes @response.body, "http://#{@blog.subdomain}.example.com/notes/#{@post.slug}"

    get "/feed.xml"
    assert_response :success
    assert_includes @response.body, "http://#{@blog.subdomain}.example.com/notes/#{@post.slug}"
  end

  test "canonical link tag reflects the format" do
    @blog.update!(post_url_format: "prefix", post_url_prefix: "notes")

    get "/notes/#{@post.slug}"

    assert_select "link[rel=canonical][href=?]", "http://#{@blog.subdomain}.example.com/notes/#{@post.slug}"
  end

  test "lets the custom domain redirect take precedence" do
    @blog = blogs(:annie)
    host_subdomain! @blog.subdomain
    post = @blog.posts.visible.first

    get "/posts/#{post.slug}"

    assert_redirected_to "http://#{@blog.custom_domain}/posts/#{post.slug}"
    assert_equal 301, @response.status
  end

  test "redirects a prefixed posts path for hidden posts" do
    post = @blog.posts.create!(
      title: "Hidden Post",
      content: "This is hidden content",
      status: :published,
      hidden: true
    )

    get "/posts/#{post.slug}"

    assert_redirected_to "http://#{@blog.subdomain}.example.com/#{post.slug}"
    assert_equal 301, @response.status
  end

  test "does not redirect a prefixed posts path for draft posts" do
    post = @blog.posts.create!(title: "Draft Post", content: "Draft content", status: :draft)

    get "/posts/#{post.slug}"

    assert_response :not_found
  end

  test "does not redirect a prefixed posts path for future posts" do
    post = @blog.posts.create!(
      title: "Future Post",
      content: "Future content",
      status: :published,
      published_at: 1.day.from_now
    )

    get "/posts/#{post.slug}"

    assert_response :not_found
  end

  test "does not redirect a prefixed posts path for missing content" do
    get "/posts/missing"

    assert_response :not_found
  end

  test "keeps the posts archive route ahead of the prefixed posts redirect" do
    get "/posts"

    assert_response :success
    assert_template "blogs/posts/index"
  end

  test "keeps the embedded posts route ahead of the prefixed posts redirect" do
    get "/posts/embedded", params: { style: "card", frame_id: "posts" }

    assert_response :success
    assert_template "blogs/embedded_posts/index"
  end

  test "keeps the upvote statuses route ahead of the dynamic prefix route" do
    get "/upvotes/statuses", params: { post_tokens: [] }

    assert_response :success
  end
end
