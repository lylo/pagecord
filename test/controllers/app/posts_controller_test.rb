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

  test "should create hidden post" do
    assert_difference("@user.blog.posts.count") do
      post app_posts_url, params: {
        post: { title: "Hidden Post", content: "Hidden content", hidden: true }
      }
    end

    assert_redirected_to app_posts_url
    created_post = @user.blog.posts.last
    assert created_post.published?
    assert created_post.hidden?
    assert_equal "Hidden Post", created_post.title
  end

  test "should create public post when hidden is false" do
    assert_difference("@user.blog.posts.count") do
      post app_posts_url, params: {
        post: { title: "Public Post", content: "Public content", hidden: false }
      }
    end

    assert_redirected_to app_posts_url
    created_post = @user.blog.posts.last
    assert created_post.published?
    assert_not created_post.hidden?
    assert_equal "Public Post", created_post.title
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
        assert_equal "Update Draft", elements.first.text.strip
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

  # Search functionality tests

  test "should search posts by title" do
    @user.blog.posts.create!(title: "Rails Tutorial", content: "Learning Rails")
    @user.blog.posts.create!(title: "Python Guide", content: "Learning Python")
    @user.blog.posts.create!(title: "JavaScript Basics", content: "Learning JS")

    get app_posts_path(search: "Rails")

    assert_response :success
    assert_includes @response.body, "Rails Tutorial"
    assert_not_includes @response.body, "Python Guide"
    assert_not_includes @response.body, "JavaScript Basics"
  end

  test "should search posts by content" do
    @user.blog.posts.create!(title: "Tutorial One", content: "This covers Ruby programming")
    @user.blog.posts.create!(title: "Tutorial Two", content: "This covers Python programming")

    get app_posts_path(search: "Ruby")

    assert_response :success
    assert_includes @response.body, "Tutorial One"
    assert_not_includes @response.body, "Tutorial Two"
  end

  test "should search posts by tags" do
    @user.blog.posts.create!(title: "Web Dev Post", content: "About development", tags_string: "rails, backend")
    @user.blog.posts.create!(title: "Mobile Post", content: "About mobile apps", tags_string: "ios, swift")

    get app_posts_path(search: "rails")

    assert_response :success
    assert_includes @response.body, "Web Dev Post"
    assert_not_includes @response.body, "Mobile Post"
  end

  test "should search drafts as well as published posts" do
    @user.blog.posts.create!(title: "Published Rails Post", content: "Published content", tags_string: "rails")
    @user.blog.posts.create!(title: "Draft Rails Post", content: "Draft content", tags_string: "rails", status: :draft)

    get app_posts_path(search: "rails")

    assert_response :success
    assert_includes @response.body, "Published Rails Post"
    assert_includes @response.body, "Draft Rails Post"
  end

  test "should return empty results for non-matching search" do
    @user.blog.posts.create!(title: "Rails Post", content: "About Rails")

    get app_posts_path(search: "Python")

    assert_response :success
    assert_not_includes @response.body, "Rails Post"
  end

  test "should handle empty search parameter" do
    @user.blog.posts.create!(title: "Test Post", content: "Test content")

    get app_posts_path(search: "")

    assert_response :success
    assert_includes @response.body, "Test Post"
  end

  test "should only show drafts on page 1 when searching" do
    # Create enough posts to span multiple pages
    30.times do |i|
      @user.blog.posts.create!(title: "Published Post #{i}", content: "Published content #{i}")
    end
    @user.blog.posts.create!(title: "Draft Post", content: "Draft content", status: :draft)

    # Page 1 should show drafts
    get app_posts_path(search: "Post")
    assert_response :success
    assert_includes @response.body, "Draft Post"

    # Page 2 should not show drafts
    get app_posts_path(search: "Post", page: 2)
    assert_response :success
    assert_not_includes @response.body, "Draft Post"
  end

  test "app area should be inaccessible on custom domain" do
    post = posts(:four)
    login_as post.blog.user

    get app_posts_url, headers: { "HOST" => post.blog.custom_domain }

    assert_redirected_to root_url(host: post.blog.custom_domain)
  end
end
