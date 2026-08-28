require "application_system_test_case"

class MediaEmbedsTest < ApplicationSystemTestCase
  setup do
    @blog = blogs(:joel)
  end

  test "a link on its own line becomes an embed" do
    post = publish(%(<p><a href="https://open.spotify.com/album/53Rf">https://open.spotify.com/album/53Rf</a></p>))

    use_subdomain(@blog.subdomain)
    visit blog_post_path(post.slug)

    assert_selector "article iframe[src*='open.spotify.com/embed']", wait: 5
  end

  # A URL with prose beside it is a sentence, and a block-level player would break
  # the line in half. The editor leaves these alone, so the published post has to
  # as well, or writing one thing and reading another.
  test "a link in the middle of a sentence stays a link" do
    post = publish(%(<p>Listen to <a href="https://open.spotify.com/album/53Rf">https://open.spotify.com/album/53Rf</a> today.</p>))

    use_subdomain(@blog.subdomain)
    visit blog_post_path(post.slug)

    assert_selector "article a[href='https://open.spotify.com/album/53Rf']"
    assert_no_selector "article iframe"
  end

  # Inline wrappers must not defeat the sentence rule: prose beside the <em> is
  # still prose beside the link.
  test "a link mid-sentence inside formatting stays a link" do
    post = publish(%(<p>Listen to <em><a href="https://open.spotify.com/album/53Rf">https://open.spotify.com/album/53Rf</a></em> today.</p>))

    use_subdomain(@blog.subdomain)
    visit blog_post_path(post.slug)

    assert_selector "article a[href='https://open.spotify.com/album/53Rf']"
    assert_no_selector "article iframe"
  end

  # Trix put several lines in one block separated by <br>, so a link can be alone on
  # its line without being alone in its paragraph.
  test "a link alone on a line separated by breaks becomes an embed" do
    post = publish(%(<div>Some words<br><a href="https://open.spotify.com/album/53Rf">https://open.spotify.com/album/53Rf</a><br>more words</div>))

    use_subdomain(@blog.subdomain)
    visit blog_post_path(post.slug)

    assert_selector "article iframe[src*='open.spotify.com/embed']", wait: 5
  end

  private
    def publish(html)
      @blog.posts.create!(title: "Embeds", content: html, published_at: Time.current)
    end
end
