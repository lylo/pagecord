require "test_helper"

class App::Settings::BlogsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
  end

  test "should get show" do
    get app_settings_blog_url

    assert_select "h3", { count: 1, text: "Blog Settings" }
    assert_select "h3", { count: 1, text: "Advanced" }
    assert_select "h4", { count: 1, text: "Custom Domain" }
    assert_select "h4", { count: 1, text: "Discoverability" }
    assert_select "h4", { count: 1, text: "Google Site Verification" }
    assert_select "h4", { count: 1, text: "Links" }
    assert_select "h4", { count: 1, text: "Fediverse Author Attribution" }
    assert_select "p", text: /Your full Fediverse handle, not your profile URL/
    assert_select "input[name='blog[fediverse_author_attribution]'][placeholder='e.g. @you@mastodon.social']"
    assert_response :success
  end

  test "should show custom domain disabled if not subscribed" do
    login_as users(:vivian)

    get app_settings_blog_url

    assert_select "h4", { count: 1, text: "Custom Domain" }
    assert_select "input[name='blog[custom_domain]'][disabled]"
    assert_response :success
  end

  test "should update blog custom domain" do
    patch app_settings_blog_url, params: { blog: { custom_domain: "newdomain.com" } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal "newdomain.com", @blog.reload.custom_domain
  end

  test "should not remove domain that doesn't belong to blog" do
    blog_with_domain = blogs(:annie)  # Already has a custom domain
    @blog.update!(custom_domain: "mydomain.com")

    # Attempt to remove annie's domain from joel's blog by spoofing params
    patch app_settings_blog_url,
      params: {
        blog: {
          custom_domain: "",
          _custom_domain_was: blog_with_domain.custom_domain  # Attempting to spoof
        }
      },
      as: :turbo_stream

    assert_nil @blog.reload.custom_domain
    assert_equal "annie.blog", blog_with_domain.reload.custom_domain
  end

  test "should update search engine visibility" do
    patch app_settings_blog_url, params: { blog: { allow_search_indexing: false } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal false, @blog.reload.allow_search_indexing
  end

  test "should show custom robots controls for subscriber" do
    get app_settings_blog_url

    assert_select "input[type='checkbox'][name='blog[use_custom_robots_txt]']:not([disabled])", count: 1
    assert_select "textarea#blog_custom_robots_txt", count: 1
  end

  test "should show disabled custom robots controls for non-subscriber" do
    login_as users(:vivian)

    get app_settings_blog_url

    assert_select "input[type='checkbox'][name='blog[use_custom_robots_txt]'][disabled]", count: 1
    assert_select "p", /Customising crawler rules is available with a subscription/
  end

  test "subscriber should save custom robots txt" do
    custom_robots_txt = "User-agent: Bubbles\nAllow: /\n"

    patch app_settings_blog_url, params: {
      blog: { custom_robots_txt: custom_robots_txt, use_custom_robots_txt: "1" }
    }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal custom_robots_txt, @blog.reload.custom_robots_txt
  end

  test "subscriber should clear custom robots txt by unticking" do
    @blog.update!(custom_robots_txt: "User-agent: Bubbles\nAllow: /\n")

    patch app_settings_blog_url, params: {
      blog: { custom_robots_txt: "User-agent: Bubbles\nAllow: /\n", use_custom_robots_txt: "0" }
    }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_nil @blog.reload.custom_robots_txt
  end

  test "updating from a form without the robots checkbox preserves custom robots txt" do
    custom_robots_txt = "User-agent: Bubbles\nAllow: /\n"
    @blog.update!(custom_robots_txt: custom_robots_txt)

    patch app_settings_blog_url, params: {
      blog: { allow_search_indexing: true }
    }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal custom_robots_txt, @blog.reload.custom_robots_txt
  end

  test "subscriber save with invalid custom robots txt renders errors" do
    patch app_settings_blog_url, params: {
      blog: { custom_robots_txt: "Host: example.com\n", use_custom_robots_txt: "1" }
    }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_select ".field-error", /unsupported directive/
  end

  test "non-subscriber custom robots txt is ignored" do
    login_as users(:vivian)

    patch app_settings_blog_url, params: {
      blog: { custom_robots_txt: "User-agent: Bubbles\nAllow: /\n", use_custom_robots_txt: "1" }
    }, as: :turbo_stream

    assert_nil users(:vivian).blog.reload.custom_robots_txt
  end

  test "should update fediverse author attribution" do
    patch app_settings_blog_url, params: { blog: { fediverse_author_attribution: "@example@mastodon.social" } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal "@example@mastodon.social", @blog.reload.fediverse_author_attribution
  end

  test "should update google site verification" do
    patch app_settings_blog_url, params: { blog: { google_site_verification: "GzmHXW-PA_FXh29Dp31_cgsIx6ZY_h9OgR6r8DZ0I44" } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal "GzmHXW-PA_FXh29Dp31_cgsIx6ZY_h9OgR6r8DZ0I44", @blog.reload.google_site_verification
  end

  test "should clear google site verification" do
    @blog.update!(google_site_verification: "existing_code")

    patch app_settings_blog_url, params: { blog: { google_site_verification: "" } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal "", @blog.reload.google_site_verification
  end

  test "should not update google site verification with invalid format" do
    patch app_settings_blog_url, params: { blog: { google_site_verification: "invalid code with spaces" } }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_nil @blog.reload.google_site_verification
  end

  test "should update locale" do
    patch app_settings_blog_url, params: { blog: { locale: "es" } }

    assert_redirected_to app_settings_path
    assert_equal "es", @blog.reload.locale
  end

  test "should not update with invalid locale" do
    patch app_settings_blog_url, params: { blog: { locale: "invalid" } }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_equal "en", @blog.reload.locale
  end

  test "should show language section" do
    get app_settings_blog_url

    assert_select "h4", { count: 1, text: "Language" }
    assert_select "select[name='blog[locale]']", count: 1
    assert_response :success
  end

  test "should update show_subscription_in_header" do
    patch app_settings_blog_url, params: { blog: { show_subscription_in_header: false } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal false, @blog.reload.show_subscription_in_header
  end

  test "should update show_subscription_in_footer" do
    patch app_settings_blog_url, params: { blog: { show_subscription_in_footer: false } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal false, @blog.reload.show_subscription_in_footer
  end

  test "should update show_metrics" do
    patch app_settings_blog_url, params: { blog: { show_metrics: false } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal false, @blog.reload.show_metrics
  end

  test "should update external links in new tab" do
    patch app_settings_blog_url, params: { blog: { external_links_in_new_tab: true } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal true, @blog.reload.external_links_in_new_tab
  end

  test "should not allow non-subscribed user to update subscription location settings" do
    login_as users(:vivian)

    patch app_settings_blog_url, params: {
      blog: {
        show_subscription_in_header: false,
        show_subscription_in_footer: false
      }
    }, as: :turbo_stream

    blog = users(:vivian).blog.reload
    assert blog.show_subscription_in_header
    assert blog.show_subscription_in_footer
  end

  test "should set a blog password" do
    patch app_settings_blog_url, params: { blog: { use_password: "1", password: "letmein" } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert @blog.reload.password_protected?
    assert @blog.authenticate("letmein")
  end

  test "should remove a blog password" do
    @blog.update!(password: "letmein")

    patch app_settings_blog_url, params: { blog: { use_password: "0" } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_not @blog.reload.password_protected?
  end

  test "should reject password protection with no password" do
    patch app_settings_blog_url, params: { blog: { use_password: "1", password: "" } }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_not @blog.reload.password_protected?
  end
end
