require "test_helper"
require "mocha/minitest"

class App::LinkPreviewsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user

    Resolv.stubs(:getaddresses).returns([ "93.184.216.34" ])
  end

  test "returns the Open Graph title, description and image" do
    stub_page <<~HTML
      <html><head>
        <meta property="og:title" content="Summer 2026 was the hottest on record"/>
        <meta property="og:description" content="Provisional Met Office data."/>
        <meta property="og:image" content="https://example.com/hero.jpg"/>
      </head></html>
    HTML
    stub_image

    post app_link_previews_path, params: { url: article_url }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Summer 2026 was the hottest on record", json["title"]
    assert_equal "Provisional Met Office data.", json["description"]
    assert json["image"]["attachable_sgid"].present?
    assert_equal "image/jpeg", json["image"]["content_type"]
    assert_equal 1200, json["image"]["width"]
    assert_equal 630, json["image"]["height"]
    assert_kind_of ActiveStorage::Blob,
      GlobalID::Locator.locate_signed(json["image"]["attachable_sgid"], for: ActionText::Attachable::LOCATOR_NAME)
  end

  test "falls back to the title tag and returns no image when the page has no Open Graph tags" do
    stub_page "<html><head><title>A plain page</title></head></html>"

    post app_link_previews_path, params: { url: article_url }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "A plain page", json["title"]
    assert_nil json["description"]
    assert_nil json["image"]
  end

  test "rejects a page with no title at all" do
    stub_page "<html><head></head></html>"

    post app_link_previews_path, params: { url: article_url }

    assert_response :unprocessable_entity
  end

  test "rejects a non-HTTPS URL without fetching it" do
    URI.expects(:open).never

    post app_link_previews_path, params: { url: "http://example.com/article" }

    assert_response :unprocessable_entity
  end

  test "rejects a host that resolves to a private address without fetching it" do
    Resolv.stubs(:getaddresses).returns([ "10.0.0.1" ])
    URI.expects(:open).never

    post app_link_previews_path, params: { url: article_url }

    assert_response :unprocessable_entity
  end

  test "skips the image when it is not a supported type" do
    stub_page <<~HTML
      <html><head>
        <meta property="og:title" content="A story"/>
        <meta property="og:image" content="https://example.com/hero.svg"/>
      </head></html>
    HTML
    FastImage.stubs(:size).returns(nil)
    FastImage.stubs(:type).returns(:svg)

    post app_link_previews_path, params: { url: article_url }

    assert_response :success
    assert_nil JSON.parse(response.body)["image"]
  end

  test "skips the image when the upload quota does not allow images" do
    stub_page <<~HTML
      <html><head>
        <meta property="og:title" content="A story"/>
        <meta property="og:image" content="https://example.com/hero.jpg"/>
      </head></html>
    HTML
    UploadQuota.any_instance.stubs(:allowed_content_types).returns([])

    post app_link_previews_path, params: { url: article_url }

    assert_response :success
    assert_nil JSON.parse(response.body)["image"]
  end

  test "requires a signed-in user" do
    logout

    post app_link_previews_path, params: { url: article_url }

    assert_response :redirect
  end

  private

    def article_url
      "https://example.com/article"
    end

    def stub_page(html)
      URI.stubs(:open).with(article_url, has_entry(redirect: false)).returns(StringIO.new(html))
    end

    def stub_image
      FastImage.stubs(:size).returns([ 1200, 630 ])
      FastImage.stubs(:type).returns(:jpeg)
      URI.stubs(:open)
         .with("https://example.com/hero.jpg", has_entry(redirect: false))
         .returns(StringIO.new(file_fixture("space.jpg").binread))
    end
end
