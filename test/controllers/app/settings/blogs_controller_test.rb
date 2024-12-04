require "test_helper"

class App::Settings::BlogsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
  end

  test "should get index" do
    get app_settings_blogs_url

    assert_select "h3", { count: 1, text: "Bio" }
    assert_select "h3", { count: 1, text: "Title" }
    assert_select "h3", { count: 1, text: "Custom Domain" }
    assert_response :success
  end

  test "should not show title or custom domain if not subscribed" do
    login_as users(:vivian)

    get app_settings_blogs_url

    assert_select "h3", { count: 0, text: "Title" }
    assert_select "h3", { count: 0, text: "Custom Domain" }
    assert_response :success
  end

  test "should update blog bio" do
    patch app_settings_blog_url(@blog), params: { blog: { bio: "New bio" } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal "New bio", @blog.reload.bio.to_plain_text
  end

  test "should update blog custom domain" do
    patch app_settings_blog_url(@blog), params: { blog: { custom_domain: "newdomain.com" } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal "newdomain.com", @blog.reload.custom_domain
  end

  test "should call hatchbox when adding custom domain" do
    assert_performed_jobs 1 do
      patch app_settings_blog_url(@blog), params: { blog: { custom_domain: "newdomain.com" } }, as: :turbo_stream
    end
  end

  test "should call hatchbox when removing custom domain" do
    user = users(:annie)
    login_as user

    assert_performed_jobs 1 do
      patch app_settings_blog_url(user.blog), params: { blog: { custom_domain: "" } }, as: :turbo_stream
    end
  end

  test "should not call hatchbox if nil custom domain is changed to empty string" do
    assert_performed_jobs 0 do
      patch app_settings_blog_url(@blog), params: { blog: { custom_domain: "" } }, as: :turbo_stream
    end
  end

  test "should not call hatchbox if custom domain is changed to same value" do
    assert_performed_jobs 0 do
      patch app_settings_blog_url(blogs(:annie)), params: { blog: { custom_domain: blogs(:annie).custom_domain } }, as: :turbo_stream
    end
  end

  test "should raise an error after 5 custom domain changes" do
    user = users(:annie)

    (1..5).each do |i|
      user.blog.custom_domain_changes.create!(custom_domain: "newdomain#{i}.com")
    end

    assert_raises do
      AddCustomDomainJob.perform_now(user.blog.id, "newdomain6.com")
    end
  end
end
