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

  test "should not show avatar or custom domain if not subscribed" do
    login_as users(:vivian)

    get app_settings_blogs_url

    assert_select "h3", { count: 0, text: "Avatar" }
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

  test "should call hatchbox when changing custom domain" do
    @blog.update!(custom_domain: "olddomain.com")

    assert_enqueued_jobs 2 do
      patch app_settings_blog_url(@blog),
        params: { blog: { custom_domain: "newdomain.com" } },
        as: :turbo_stream

      assert_enqueued_with(job: RemoveCustomDomainJob, args: [ @blog.id, "olddomain.com" ])
      assert_enqueued_with(job: AddCustomDomainJob, args: [ @blog.id, "newdomain.com" ])
    end

    assert_equal "newdomain.com", @blog.reload.custom_domain
  end

  test "should not remove domain that doesn't belong to blog" do
    blog_with_domain = blogs(:annie)  # Already has a custom domain
    @blog.update!(custom_domain: "mydomain.com")

    # Attempt to remove annie's domain from joel's blog by spoofing params
    assert_enqueued_jobs 1 do  # Should only remove mydomain.com, not annie's domain
      patch app_settings_blog_url(@blog),
        params: {
          blog: {
            custom_domain: "",
            _custom_domain_was: blog_with_domain.custom_domain  # Attempting to spoof
          }
        },
        as: :turbo_stream
    end

    assert_nil @blog.reload.custom_domain
    assert_equal "annie.blog", blog_with_domain.reload.custom_domain
  end

  test "should raise an error after 20 custom domain changes" do
    user = users(:annie)

    (1..20).each do |i|
      user.blog.custom_domain_changes.create!(custom_domain: "newdomain#{i}.com")
    end

    assert_raises do
      AddCustomDomainJob.perform_now(user.blog.id, "newdomain6.com")
    end
  end

  test "should add a new social link for valid platform" do
    assert_difference -> { @blog.social_links.count }, 1 do
      patch app_settings_blog_url(@blog), params: {
          blog: {
            social_links_attributes: {
              "#{Time.now.to_i}": { platform: "X", url: "https://x.com/whatever" }
            }
          }
        }, as: :turbo_stream
    end
  end

  test "should now add a new social link for invalid platform" do
    assert_no_difference -> { @blog.social_links.count } do
      patch app_settings_blog_url(@blog), params: {
          blog: {
            social_links_attributes: {
              "#{Time.now.to_i}": { platform: "pagecord", url: "https://pagecord.com/whatever" }
            }
          }
        }, as: :turbo_stream
    end
  end

  test "should delete an existing new social link" do
    assert_difference -> { @blog.social_links.count }, -1 do
      patch app_settings_blog_url(@blog), params: {
          blog: {
            social_links_attributes: {
              "0": { "_destroy": true, id: @blog.social_links.first.id }
            }
          }
        }, as: :turbo_stream
    end
  end
end
