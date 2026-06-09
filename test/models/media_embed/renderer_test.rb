require "test_helper"

class MediaEmbed::RendererTest < ActiveSupport::TestCase
  setup do
    @cache = ActiveSupport::Cache::MemoryStore.new
    Rails.stubs(:cache).returns(@cache)
    @renderer = MediaEmbed::Renderer.new(view: ApplicationController.helpers)
    Rails.cache.clear
  end

  test "renders youtube embeds" do
    html = @renderer.render("https://youtu.be/abc123")

    assert_includes html, "video-embed-container"
    assert_includes html, "https://www.youtube-nocookie.com/embed/abc123"
  end

  test "renders spotify embeds" do
    html = @renderer.render("https://open.spotify.com/track/7ouMYWpwJ422jRcDASZB7P")

    assert_includes html, "https://open.spotify.com/embed/track/7ouMYWpwJ422jRcDASZB7P"
  end

  test "returns nil for unsupported URLs" do
    assert_nil @renderer.render("https://example.com/not-embeddable")
  end

  test "caches bandcamp embed URL resolution" do
    url = "https://artist.bandcamp.com/album/example"
    html = <<~HTML
      <html>
        <head>
          <meta property="og:video" content="https://bandcamp.com/EmbeddedPlayer/v=2/album=123/">
        </head>
      </html>
    HTML

    URI.expects(:open).once.with(url, open_timeout: 2, read_timeout: 3).returns(StringIO.new(html))

    2.times do
      rendered = @renderer.render(url)
      assert_includes rendered, "https://bandcamp.com/EmbeddedPlayer/v=2/album=123/"
    end
  end

  test "caches bluesky handle resolution" do
    url = "https://bsky.app/profile/pagecord.com/post/abc123"
    resolved_url = "https://public.api.bsky.app/xrpc/com.atproto.identity.resolveHandle?handle=pagecord.com"

    URI.expects(:open)
      .once
      .with(resolved_url, open_timeout: 2, read_timeout: 3)
      .returns(StringIO.new({ did: "did:plc:pagecord" }.to_json))

    2.times do
      rendered = @renderer.render(url)
      assert_includes rendered, "https://embed.bsky.app/embed/did:plc:pagecord/app.bsky.feed.post/abc123"
    end
  end
end
