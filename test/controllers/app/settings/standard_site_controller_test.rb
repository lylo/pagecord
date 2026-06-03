require "test_helper"

class App::Settings::StandardSiteControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
  end

  test "should get show" do
    get app_settings_standard_site_url

    assert_response :success
    assert_select "h3", text: "Bluesky / Standard.site"
  end

  test "connects bluesky and enqueues publication sync" do
    StandardSite::Client.expects(:connect).with(
      handle: "joel.bsky.social",
      app_password: "app-password",
      pds_url: "https://bsky.social"
    ).returns({
      "handle" => "joel.bsky.social",
      "did" => "did:plc:joel123",
      "accessJwt" => "access-token",
      "refreshJwt" => "refresh-token"
    })

    assert_enqueued_with(job: StandardSite::SyncPublicationJob, args: [ @blog.id ]) do
      post app_settings_standard_site_url, params: {
        standard_site: {
          handle: "joel.bsky.social",
          app_password: "app-password",
          pds_url: "https://bsky.social"
        }
      }
    end

    assert_redirected_to app_settings_standard_site_url
    assert_equal "joel.bsky.social", @blog.reload.standard_site_account.handle
    assert_equal "did:plc:joel123", @blog.standard_site_account.did
    assert @blog.standard_site_publication.present?
    assert_not_includes @blog.standard_site_account.access_jwt_ciphertext, "access-token"
  end

  test "does not connect for free users" do
    user = users(:vivian)
    login_as user

    assert_no_enqueued_jobs do
      post app_settings_standard_site_url, params: {
        standard_site: {
          handle: "vivian.bsky.social",
          app_password: "app-password",
          pds_url: "https://bsky.social"
        }
      }
    end

    assert_redirected_to app_settings_standard_site_url
    assert_nil user.blog.reload.standard_site_account
  end

  test "disconnects bluesky and removes local standard site records" do
    account = @blog.create_standard_site_account!(
      handle: "joel.bsky.social",
      did: "did:plc:joel123",
      pds_url: "https://bsky.social",
      connected_at: Time.current
    )
    account.access_jwt = "access-token"
    account.refresh_jwt = "refresh-token"
    account.save!

    @blog.create_standard_site_publication!(at_uri: "at://did:plc:joel123/site.standard.publication/self", sync_status: :synced)
    @blog.posts.first.create_standard_site_document!(
      at_uri: "at://did:plc:joel123/site.standard.document/#{@blog.posts.first.token}",
      rkey: @blog.posts.first.token,
      sync_status: :synced
    )

    delete app_settings_standard_site_url

    assert_redirected_to app_settings_standard_site_url
    assert_nil @blog.reload.standard_site_account
    assert_nil @blog.standard_site_publication
    assert_equal 0, StandardSite::Document.where(post: @blog.all_posts).count
  end
end
