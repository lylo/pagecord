require "test_helper"

class App::PostsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:vivian)
    login_as @user
  end

  test "should get new post page" do
    get new_app_post_url

    assert_response :success
    assert_select "form#post-form" do
      assert_select "input[type=submit][value='Publish Post']"
      assert_select "button[type=submit]" do |elements|
        assert_equal "Save Draft", elements.first.text.strip
      end
    end
  end

  test "should get root" do
    get app_root_url
    assert_response :success
  end

  test "should get posts index" do
    get app_posts_url

    assert_response :success
    assert_select "div#draft_posts"
  end

  test "should publish post" do
    assert_difference("@user.blog.posts.count") do
      post app_posts_url, params: {
        post: { title: "New Post", content: "New content" }
      }
    end

    assert_redirected_to app_posts_url
    assert @user.blog.posts.last.published?
    assert_equal "New Post", @user.blog.posts.last.title
    assert_equal "New content", @user.blog.posts.last.content.to_s.strip
  end

  test "should save draft post" do
    assert_difference("@user.blog.posts.count") do
      post app_posts_url, params: {
        post: { title: "New Post", content: "New content" },
        button: "save_draft"
      }
    end

    assert_redirected_to app_posts_url
    assert @user.blog.posts.last.draft?
  end

  test "should destroy post" do
    assert_difference("@user.blog.posts.count", -1) do
      delete app_post_url(@user.blog.posts.first)
    end
    assert_redirected_to app_posts_url
  end

  test "should show edit post page for published post" do
    get edit_app_post_url(@user.blog.posts.published.first)

    assert_response :success
    assert_select "form#post-form" do
      assert_select "input[type=submit][value='Update Post']"
      assert_select "button[type=submit]" do |elements|
        assert_equal "Unpublish", elements.first.text.strip
      end
    end
  end

  test "should show edit post page for draft post" do
    get edit_app_post_url(@user.blog.posts.draft.first)

    assert_response :success
    assert_select "form#post-form" do
      assert_select "input[type=submit][value='Publish Post']"
      assert_select "button[type=submit]" do |elements|
        assert_equal "Save Draft", elements.first.text.strip
      end
    end
  end

  test "should update post" do
    patch app_post_url(@user.blog.posts.first), params: {
      post: {
        title: "New Title",
        content: "New content",
        published_at: 1.month.ago.to_date,
        canonical_url: "https://example.com"
      }
    }

    assert_redirected_to app_posts_url
    assert_equal "New Title", @user.blog.posts.first.title
    assert_equal "New content", @user.blog.posts.first.content.to_s.strip
    assert_equal 1.month.ago.to_date, @user.blog.posts.first.published_at
    assert_equal "https://example.com", @user.blog.posts.first.canonical_url
  end

  test "app area should be inaccessible on custom domain" do
    post = posts(:four)
    login_as post.blog.user

    get app_posts_url, headers: { "HOST" => post.blog.custom_domain }

    assert_redirected_to root_url(host: post.blog.custom_domain)
  end
end
