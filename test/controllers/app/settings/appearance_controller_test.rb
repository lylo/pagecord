require "test_helper"

class App::Settings::AppearanceControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
  end

  test "should get index" do
    get app_settings_appearance_index_url

    assert_select "h3", { count: 1, text: "Bio" }
    assert_select "h3", { count: 1, text: "Title" }
    assert_select "h3", { count: 1, text: "Layout" }
    assert_select "h3", { count: 1, text: "Social Links" }
    assert_response :success
  end

  test "should show avatar section if subscribed" do
    get app_settings_appearance_index_url

    assert_select "h3", { count: 1, text: "Avatar" }
    assert_response :success
  end

  test "should not show avatar section if not subscribed" do
    login_as users(:vivian)

    get app_settings_appearance_index_url

    assert_select "h3", { count: 0, text: "Avatar" }
    assert_response :success
  end

  test "should update blog bio" do
    patch app_settings_appearance_url(@blog), params: { blog: { bio: "New bio" } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal "New bio", @blog.reload.bio.to_plain_text
  end

  test "should update blog title" do
    patch app_settings_appearance_url(@blog), params: { blog: { title: "New Title" } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal "New Title", @blog.reload.title
  end

  test "should update blog layout" do
    patch app_settings_appearance_url(@blog), params: { blog: { layout: "title_layout" } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal "title_layout", @blog.reload.layout
  end

  test "should update show branding flag for subscriber" do
    patch app_settings_appearance_url(@blog), params: { blog: { show_branding: false } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_not @blog.reload.show_branding
    assert_select "input#blog_show_branding[checked]", false
  end

  test "should not update show branding flag for non-subscriber" do
    @user = users(:vivian)
    login_as @user
    @blog = @user.blog

    patch app_settings_appearance_url(@blog), params: { blog: { show_branding: false } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert @blog.reload.show_branding
    assert_select "input#blog_show_branding", false
  end

  test "should update avatar if subscribed" do
    file = fixture_file_upload("avatar.png", "image/png")
    patch app_settings_appearance_url(@blog), params: { blog: { avatar: file } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert @blog.reload.avatar.attached?
  end

  test "should not update avatar if not subscribed" do
    login_as users(:vivian)
    non_subscribed_blog = users(:vivian).blog

    file = fixture_file_upload("avatar.png", "image/png")
    patch app_settings_appearance_url(non_subscribed_blog), params: { blog: { avatar: file } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_not non_subscribed_blog.reload.avatar.attached?
  end

  test "should add a new social link for valid platform" do
    assert_difference -> { @blog.social_links.count }, 1 do
      patch app_settings_appearance_url(@blog), params: {
          blog: {
            social_links_attributes: {
              "#{Time.current.to_i}": { platform: "X", url: "https://x.com/whatever" }
            }
          }
        }, as: :turbo_stream
    end
  end

  test "should not add a new social link for invalid platform" do
    assert_no_difference -> { @blog.social_links.count } do
      patch app_settings_appearance_url(@blog), params: {
          blog: {
            social_links_attributes: {
              "#{Time.current.to_i}": { platform: "pagecord", url: "https://pagecord.com/whatever" }
            }
          }
        }, as: :turbo_stream
    end
  end

  test "should delete an existing social link" do
    assert_difference -> { @blog.social_links.count }, -1 do
      patch app_settings_appearance_url(@blog), params: {
          blog: {
            social_links_attributes: {
              "0": { "_destroy": true, id: @blog.social_links.first.id }
            }
          }
        }, as: :turbo_stream
    end
  end
end
