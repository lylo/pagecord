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

  # Finding one old comment in the whole-blog archive is the hard case.
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

  test "a comment reached from a post sends you back to that post" do
    get app_comment_path(post_comments(:approved), post: @post.token)

    assert_response :success
    assert_select "a.btn-secondary[href=?]", app_post_comments_path(@post), text: "Back to comments"
  end

  test "a comment reached from the whole blog list sends you back there" do
    get app_comment_path(post_comments(:approved))

    assert_response :success
    assert_select "a.btn-secondary[href=?]", app_comments_path, text: "Back to comments"
  end

  test "ignores an origin that isn't the comment's own post" do
    get app_comment_path(post_comments(:approved), post: posts(:two).token)

    assert_response :success
    assert_select "a.btn-secondary[href=?]", app_comments_path
  end

  test "approving from a post keeps you on that post" do
    post app_comment_approval_path(post_comments(:pending), post: @post.token)

    assert_redirected_to app_post_comments_path(@post)
  end

  # /app/posts/:token/comments contains both words, so a substring match on the
  # path lights up two tabs at once.
  test "the per-post view highlights Comments alone in the nav" do
    get app_post_comments_path(@post)

    assert_response :success
    assert_select "a[href=?].font-semibold", app_comments_path
    assert_select "a[href=?].font-semibold", app_posts_path, count: 0
  end

  test "the posts index still highlights Posts" do
    get app_posts_path

    assert_response :success
    assert_select "a[href=?].font-semibold", app_posts_path
    assert_select "a[href=?].font-semibold", app_comments_path, count: 0
  end

  test "can't reach another blog's post comments" do
    get app_post_comments_path(posts(:three))

    assert_response :not_found
  end

  test "published is ordered by last activity, not arrival" do
    older = @post.comments.create!(name: "Older", message: "Posted long ago", approved_at: 1.week.ago, created_at: 1.week.ago)
    @post.comments.create!(name: "Newer", message: "Posted recently", approved_at: 1.hour.ago, created_at: 1.hour.ago)

    # Replying to the older one should float it above the newer
    post app_comment_replies_path(older), params: { comment: { message: "Late reply" } }

    get app_comments_path

    assert_response :success
    assert_equal older, assigns(:approved).first
  end

  test "paginates the published archive but never the pending queue" do
    30.times { |i| @post.comments.create!(name: "Reader #{i}", message: "Comment #{i}", approved_at: Time.current) }
    5.times { |i| @post.comments.create!(name: "Waiting #{i}", message: "Pending #{i}") }

    get app_comments_path

    assert_response :success
    assert_equal Pagy::OPTIONS[:limit], assigns(:approved).size
    assert_equal 6, assigns(:pending).size, "the queue you have to act on is never paged"
    assert_select "nav.pagy"
  end

  test "shows a single comment with its reply" do
    get app_comment_path(post_comments(:approved))

    assert_response :success
    assert_select "p", text: /Great post/
    assert_select "p", text: /nearly cut that section/
  end

  test "offers no reply box once the author has already replied" do
    get app_comment_path(post_comments(:approved))

    assert_response :success
    assert_select "textarea", count: 0
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

  test "approves a comment and updates the public count" do
    comment = post_comments(:pending)

    assert_difference -> { @post.reload.comments_count }, 1 do
      post app_comment_approval_path(comment)
    end

    assert_redirected_to app_comments_path
    assert comment.reload.approved?
  end

  test "approves inline and refreshes the moderation list and nav count" do
    comment = post_comments(:pending)

    post app_comment_approval_path(comment),
      params: { comment: { message: "" } },
      as: :turbo_stream

    assert_response :success
    assert comment.reload.approved?
    assert_select "turbo-stream[action=update][target=comments_moderation]"
    assert_select "turbo-stream[action=update][target=comments_nav_pending_count]"
  end

  test "shows an inline reply error without approving the comment" do
    comment = post_comments(:pending)

    post app_comment_approval_path(comment),
      params: { comment: { message: "x" * 9.kilobytes } },
      as: :turbo_stream

    assert_response :unprocessable_entity
    assert_not comment.reload.approved?
    assert_select "turbo-stream[action=replace][target=post_comment_#{comment.id}]"
    assert_includes response.body, "Message is too long"
  end

  # blog.updated_at is what rolls the fragment key, the ETag and the Cloudflare
  # cache tag, so an approval that doesn't move it would never reach readers.
  test "approving invalidates the cached post page" do
    was = blogs(:joel).updated_at

    travel 1.second do
      post app_comment_approval_path(post_comments(:pending))
    end

    assert_operator blogs(:joel).reload.updated_at, :>, was
  end

  # The one-reply rule means an unremovable reply would be permanent.
  test "deletes a reply and returns to its comment so another can be written" do
    reply = post_comments(:author_reply)

    assert_difference "Post::Comment.count", -1 do
      delete app_comment_reply_path(post_comments(:approved), reply)
    end

    assert_redirected_to app_comment_path(post_comments(:approved))

    get app_comment_path(post_comments(:approved))
    assert_select "textarea", 1, "the reply box should come back"
  end

  test "deletes a comment" do
    assert_difference "Post::Comment.count", -1 do
      delete app_comment_path(post_comments(:pending))
    end

    assert_redirected_to app_comments_path
  end

  test "posts an author reply that is approved immediately" do
    parent = @post.comments.create!(name: "Reader", message: "A question", approved_at: Time.current)

    assert_difference "Post::Comment.count", 1 do
      post app_comment_replies_path(parent), params: { comment: { message: "Thanks!" } }
    end

    reply = parent.replies.sole
    assert reply.author?
    assert reply.approved?
  end

  test "does not post an author reply to a pending comment" do
    comment = post_comments(:pending)

    assert_no_difference "Post::Comment.count" do
      post app_comment_replies_path(comment), params: { comment: { message: "Too soon" } }
    end

    assert_response :not_found
    assert_not comment.reload.approved?
  end

  test "approves and replies in one go" do
    comment = post_comments(:pending)

    assert_difference "Post::Comment.count", 1 do
      post app_comment_approval_path(comment), params: { comment: { message: "Thanks for this!" } }
    end

    assert comment.reload.approved?
    reply = comment.replies.sole
    assert reply.author?
    assert reply.approved?
    assert_equal "Thanks for this!", reply.message
    assert_equal 4, @post.reload.comments_count, "both the comment and the reply become public"
  end

  test "approving without a reply leaves no reply behind" do
    assert_no_difference "Post::Comment.count" do
      post app_comment_approval_path(post_comments(:pending)), params: { comment: { message: "" } }
    end

    assert post_comments(:pending).reload.approved?
  end

  test "a rejected reply leaves the comment unapproved" do
    comment = post_comments(:pending)

    assert_no_difference "Post::Comment.count" do
      post app_comment_approval_path(comment), params: { comment: { message: "x" * 9.kilobytes } }
    end

    assert_not comment.reload.approved?, "approving and replying succeed or fail together"
    assert_redirected_to app_comment_path(comment)
  end

  test "a pending comment offers a reply box alongside approve" do
    get app_comment_path(post_comments(:pending))

    assert_response :success
    assert_select "form[action=?][method=post]", app_comment_approval_path(post_comments(:pending)) do
      assert_select "textarea"
      assert_select "input[type=submit][value=Approve]"
    end
  end

  test "refuses a second author reply to the same comment" do
    assert_no_difference "Post::Comment.count" do
      post app_comment_replies_path(post_comments(:approved)), params: { comment: { message: "Again" } }
    end

    assert_redirected_to app_comment_path(post_comments(:approved))
  end

  test "creating a closure closes comments without leaving the comment" do
    post app_comment_closure_path(post_comments(:approved))

    assert_not @post.reload.comments_open?
    assert_redirected_to app_comment_path(post_comments(:approved))
  end

  test "destroying a closure reopens comments" do
    @post.close_comments!

    delete app_comment_closure_path(post_comments(:approved))

    assert @post.reload.comments_open?
    assert_redirected_to app_comment_path(post_comments(:approved))
  end

  # The property a toggle could never have
  test "closing twice leaves comments closed" do
    2.times { post app_comment_closure_path(post_comments(:approved)) }

    assert_not @post.reload.comments_open?
  end

  test "closing keeps the post you came from" do
    post app_comment_closure_path(post_comments(:approved), post: @post.token)

    assert_redirected_to app_comment_path(post_comments(:approved), post: @post.token)
  end

  test "can't touch another blog's comments" do
    blogs(:annie).update!(comments_enabled: true)
    users(:annie).update!(features: [ "comments" ])
    login_as users(:annie)

    post app_comment_approval_path(post_comments(:pending))

    assert_response :not_found
    assert_not post_comments(:pending).reload.approved?
  end
end
