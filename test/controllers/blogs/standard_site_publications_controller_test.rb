require "test_helper"

class Blogs::StandardSitePublicationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    host! "#{@blog.subdomain}.#{Rails.application.config.x.domain}"
  end

  test "returns not found when standard site publication is not synced" do
    get "/.well-known/site.standard.publication"

    assert_response :not_found
  end

  test "returns synced publication at uri" do
    @blog.create_standard_site_publication!(
      at_uri: "at://did:plc:joel123/site.standard.publication/self",
      sync_status: :synced
    )

    get "/.well-known/site.standard.publication"

    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_equal "at://did:plc:joel123/site.standard.publication/self", response.body
  end

  test "works on custom domains" do
    blog = blogs(:annie)
    host! blog.custom_domain
    blog.create_standard_site_publication!(
      at_uri: "at://did:plc:annie123/site.standard.publication/self",
      sync_status: :synced
    )

    get "/.well-known/site.standard.publication"

    assert_response :success
    assert_equal "at://did:plc:annie123/site.standard.publication/self", response.body
  end
end
