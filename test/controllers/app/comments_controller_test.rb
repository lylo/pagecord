require "test_helper"

class App::CommentsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @post = posts(:one)
    @user.update!(features: @user.features | [ "comments" ])
    login_as @user
  end

  test "lists comments waiting and comments already approved" do
    get app_comments_path

    assert_response :success
    assert_select "a[href=?]", app_comment_path(post_comments(:pending))
    assert_select "a[href=?]", app_comment_path(post_comments(:approved))
    assert_select "p", text: /35mm/
    assert_select "a", text: posts(:one).display_title, message: "each row should name its post"
  end

  test "marks comments the author already replied to" do
    get app_comments_path

    assert_response :success
    assert_select "article", text: /Great post/ do
      assert_select "span.sr-only", text: "You replied to this comment."
    end
    assert_select "article#post_comment_#{post_comments(:pending).id}" do
      assert_select "span.sr-only", count: 0
    end
  end

  test "published is ordered by last activity, not arrival" do
    older = @post.comments.create!(name: "Older", message: "Posted long ago", approved_at: 1.week.ago, created_at: 1.week.ago)
    @post.comments.create!(name: "Newer", message: "Posted recently", approved_at: 1.hour.ago, created_at: 1.hour.ago)

    post app_comment_replies_path(older), params: { comment: { message: "Late reply" } }

    get app_comments_path

    assert_response :success
    assert_equal older, assigns(:approved).first
  end

  # Finding one old comment in the whole-blog archive is the hard case
  test "scopes to a single post" do
    posts(:two).comments.create!(name: "Elsewhere", message: "On another post", approved_at: Time.current)

    get app_post_comments_path(@post)

    assert_response :success
    assert_select "a[href=?]", edit_app_post_path(@post), text: @post.display_title
    assert_select "a[aria-label='View published post'][href=?]",
      blog_post_url(@post.slug, host: @post.blog.host)
    assert_select "p", text: /Great post/
    assert_select "p", text: /On another post/, count: 0
  end

  test "the whole blog view is not scoped to a post" do
    posts(:two).comments.create!(name: "Elsewhere", message: "On another post", approved_at: Time.current)

    get app_comments_path

    assert_response :success
    assert_select "h1", count: 0
    assert_select "p", text: /Great post/
    assert_select "p", text: /On another post/
  end

  test "can't reach another blog's post comments" do
    get app_post_comments_path(posts(:three))

    assert_response :not_found
  end

  test "the way back out follows the list you arrived from" do
    get app_comment_path(post_comments(:approved), post: @post.token)
    assert_select "a.btn-secondary[href=?]", app_post_comments_path(@post), text: "Back to comments"

    get app_comment_path(post_comments(:approved))
    assert_select "a.btn-secondary[href=?]", app_comments_path, text: "Back to comments"

    get app_comment_path(post_comments(:approved), post: posts(:two).token)
    assert_select "a.btn-secondary[href=?]", app_comments_path, text: "Back to comments"
  end

  test "shows a single comment with its reply, and no box to reply again" do
    get app_comment_path(post_comments(:approved))

    assert_response :success
    assert_select "p", text: /Great post/
    assert_select "p", text: /nearly cut that section/
    assert_select "textarea", count: 0
  end

  test "a pending comment offers a reply box alongside approve" do
    get app_comment_path(post_comments(:pending))

    assert_response :success
    assert_select "form[action=?][method=post]", app_comment_approval_path(post_comments(:pending)) do
      assert_select "textarea"
      assert_select "input[type=submit][value=Approve]"
    end
  end

  test "deletes a comment" do
    assert_difference "Post::Comment.count", -1 do
      delete app_comment_path(post_comments(:pending))
    end

    assert_redirected_to app_comments_path
  end

  test "redirects to settings when comments are disabled" do
    blogs(:joel).update!(comments_enabled: false)

    get app_comments_path

    assert_redirected_to app_settings_audience_index_path
  end

  test "is not found when the comments feature is disabled" do
    @user.update!(features: [])

    get app_comments_path

    assert_response :not_found
  end
end
