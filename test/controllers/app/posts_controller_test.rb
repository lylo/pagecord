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

  test "should update post and preserve page via session" do
    get edit_app_post_url(@user.blog.posts.first, page: 3)

    patch app_post_url(@user.blog.posts.first), params: {
      post: {
        title: "Updated Title",
        content: "Updated content"
      }
    }

    assert_redirected_to app_posts_url(page: 3)
    assert_equal "Updated Title", @user.blog.posts.first.title
  end

  test "should create post with tags" do
    assert_difference("Post.count") do
      post app_posts_url, params: {
        post: {
          title: "Post with Tags",
          content: "Content about Rails and JavaScript",
          tags_string: "rails, javascript, web-development"
        }
      }
    end

    created_post = @user.blog.posts.last
    assert_equal [ "javascript", "rails", "web-development" ], created_post.tag_list
    assert_equal "javascript, rails, web-development", created_post.tags_string
    assert_redirected_to app_posts_url
  end

  test "should update post with tags" do
    post = posts(:three) # This is vivian's post

    patch app_post_url(post), params: {
      post: {
        title: "Updated Post",
        content: "Updated content",
        tags_string: "ruby, rails, updated"
      }
    }

    post.reload
    assert_equal [ "rails", "ruby", "updated" ], post.tag_list
    assert_redirected_to app_posts_url
  end

  test "should preserve tags on validation errors" do
    post app_posts_url, params: {
      post: {
        title: "Invalid Post",
        content: "", # Invalid - content is required
        tags_string: "rails, javascript"
      }
    }

    assert_response :unprocessable_entity
    # The form should render with the tags input field (even if hidden) containing the submitted tags (sorted)
    assert_select "input[name='post[tags_string]']" do |elements|
      assert_equal "javascript, rails", elements.first.attr("value")
    end
  end

  # Tag filtering tests

  test "should filter posts by tag in admin view" do
    # Create posts with different tags
    @user.blog.posts.create!(content: "Rails post", tags_string: "rails, web")
    @user.blog.posts.create!(content: "Python post", tags_string: "python, backend")
    @user.blog.posts.create!(content: "General post", tags_string: "general")

    get app_posts_path(tag: "rails")

    assert_response :success
    assert_includes @response.body, "Rails post"
    assert_not_includes @response.body, "Python post"
    assert_not_includes @response.body, "General post"
  end

  test "should show tag filter indicator in admin view" do
    @user.blog.posts.create!(content: "Rails post", tags_string: "rails")

    get app_posts_path(tag: "rails")

    assert_response :success
    assert_select "div", text: /Showing posts tagged with "rails"/
    assert_select "a[href='#{app_posts_path}']", text: "Show all posts"
  end

  test "should filter drafts by tag in admin view" do
    @user.blog.posts.create!(content: "Draft Rails post", tags_string: "rails", status: :draft)
    @user.blog.posts.create!(content: "Draft Python post", tags_string: "python", status: :draft)

    get app_posts_path(tag: "rails")

    assert_response :success
    assert_includes @response.body, "Draft Rails post"
    assert_not_includes @response.body, "Draft Python post"
  end

  test "app area should be inaccessible on custom domain" do
    post = posts(:four)
    login_as post.blog.user

    get app_posts_url, headers: { "HOST" => post.blog.custom_domain }

    assert_redirected_to root_url(host: post.blog.custom_domain)
  end
end
