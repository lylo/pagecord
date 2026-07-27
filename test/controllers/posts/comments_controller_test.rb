require "test_helper"

class Posts::CommentsControllerTest < ActionDispatch::IntegrationTest
  include CommentsHelper

  setup do
    @post = posts(:one)
    host! "#{@post.blog.subdomain}.#{Rails.application.config.x.domain}"
  end

  test "the post page shows the comment icon, a count and an empty frame" do
    get blog_post_path(@post.slug)

    assert_response :success
    assert_select "a.comment-link[href=?]", post_comments_path(@post)
    assert_select ".comment-count", text: "2"
    assert_select "turbo-frame##{comments_frame_id(@post)}:empty"
  end

  test "the post page shows nothing when the thread was never open" do
    @post.comments.destroy_all
    @post.close_comments!

    get blog_post_path(@post.slug)

    assert_response :success
    assert_select "a.comment-link", count: 0
    assert_select "turbo-frame##{comments_frame_id(@post)}", count: 0
  end

  test "loads the comments frame with approved comments and a form" do
    get post_comments_path(@post)

    assert_response :success
    assert_select "turbo-frame##{comments_frame_id(@post)}"
    assert_select "form[action=?]", post_comments_path(@post)
    assert_select ".comment", 2 # the approved comment and the author's reply
    assert_select ".comment-message", text: /Great post/
  end

  test "renders Turnstile in the comment form when enabled" do
    with_turnstile_enabled do
      get post_comments_path(@post)
    end

    assert_response :success
    assert_select ".cf-turnstile"
  end

  test "paginates long threads behind a show more link" do
    25.times { |i| @post.comments.create!(name: "Reader #{i}", message: "Comment #{i}", approved_at: Time.current) }

    get post_comments_path(@post)

    assert_response :success
    assert_select ".comment-list > .comment", Posts::CommentsController::PAGE_SIZE
    assert_select "a.comments-more", text: /more comments/
  end

  test "a later page renders only its own frame" do
    25.times { |i| @post.comments.create!(name: "Reader #{i}", message: "Comment #{i}", approved_at: Time.current) }

    get post_comments_path(@post, page: 2)

    assert_response :success
    assert_select "turbo-frame##{comments_frame_id(@post, 2)}"
    assert_select "form", count: 0, message: "the form belongs on the first page only"
  end

  test "does not leak pending comments" do
    get post_comments_path(@post)

    assert_response :success
    assert_select ".comment-message", text: /35mm/, count: 0
  end

  test "is not found when the blog has comments disabled" do
    @post.blog.update!(comments_enabled: false)

    get post_comments_path(@post)

    assert_response :not_found
  end

  test "loads comments for a hidden published post shared by direct link" do
    get post_comments_path(posts(:joel_hidden))

    assert_response :success
    assert_select "form[action=?]", post_comments_path(posts(:joel_hidden))
  end

  test "is not found for a draft post" do
    get post_comments_path(posts(:joel_draft))

    assert_response :not_found
  end

  test "is not found for a future post" do
    future = @post.blog.posts.create!(
      title: "Future post",
      content: "Not yet",
      status: :published,
      published_at: 1.day.from_now
    )

    get post_comments_path(future)

    assert_response :not_found
  end

  test "is not found for a discarded post" do
    @post.discard!

    get post_comments_path(@post)

    assert_response :not_found
  end

  test "a closed thread still shows its comments but no form" do
    @post.close_comments!

    get post_comments_path(@post)

    assert_response :success
    assert_select ".comment", 2
    assert_select "form[action=?]", post_comments_path(@post), count: 0
  end

  test "creates a pending comment and queues the spam check" do
    assert_difference "Post::Comment.count", 1 do
      post post_comments_path(@post), params: comment_params.merge(spam_prevention_params(@post))
    end

    assert_response :success
    assert_enqueued_jobs 1, only: CheckPostCommentJob
    assert_not Post::Comment.last.approved?
    assert_equal 2, @post.reload.comments_count, "a pending comment must not change the public count"
  end

  test "does not create a comment on a closed thread" do
    @post.close_comments!

    assert_no_difference "Post::Comment.count" do
      post post_comments_path(@post), params: comment_params.merge(spam_prevention_params(@post))
    end

    assert_response :not_found
  end

  test "does not create a comment with a mismatched form token" do
    params = comment_params.merge(spam_prevention_params(posts(:two)))

    assert_no_difference "Post::Comment.count" do
      post post_comments_path(@post), params: params
    end

    assert_response :unprocessable_entity
  end

  test "does not create a comment when the honeypot is populated" do
    params = comment_params.merge(spam_prevention_params(@post)).merge(email_confirmation: "bot@example.com")

    assert_no_difference "Post::Comment.count" do
      post post_comments_path(@post), params: params
    end

    assert_response :unprocessable_entity
    assert_select "turbo-frame##{comments_frame_id(@post)}", message: "the frame must survive a rejection"
  end

  test "does not create a comment when Turnstile fails" do
    with_turnstile_enabled do
      Turnstile.stubs(:verify?).returns(false)

      assert_no_difference "Post::Comment.count" do
        post post_comments_path(@post), params: comment_params.merge(spam_prevention_params(@post))
      end
    end

    assert_response :unprocessable_entity
    assert_select "turbo-frame##{comments_frame_id(@post)}", message: "the frame must survive a rejected challenge"
  end

  test "does not create a comment submitted too quickly" do
    params = comment_params.merge(
      form_token: @post.signed_id(purpose: :comment_form),
      rendered_at: signed_rendered_at(1.second.ago)
    )

    assert_no_difference "Post::Comment.count" do
      post post_comments_path(@post), params: params
    end

    assert_response :unprocessable_entity
    assert_select "turbo-frame##{comments_frame_id(@post)}", message: "the frame must survive a rejection"
  end

  # The shared too_many_requests page has no turbo-frame in it, so without an
  # override the reader is left with an empty frame.
  test "a rate limited submission still returns a usable frame" do
    Posts::CommentsController.any_instance.stubs(:create).raises(ActionController::TooManyRequests)

    post post_comments_path(@post), params: comment_params.merge(spam_prevention_params(@post))

    assert_response :unprocessable_entity
    assert_select "turbo-frame##{comments_frame_id(@post)}"
    assert_select ".comment-notice", text: I18n.t("comments.rejected")
  end

  test "re-renders the frame with errors when the comment is invalid" do
    params = { comment: { name: "", message: "" } }.merge(spam_prevention_params(@post))

    assert_no_difference "Post::Comment.count" do
      post post_comments_path(@post), params: params
    end

    assert_response :unprocessable_entity
    assert_select ".form-error"
  end

  private

    def comment_params
      {
        comment: {
          name: "Test Reader",
          link: "https://example.com",
          message: "This is a test comment."
        }
      }
    end

    def spam_prevention_params(post)
      {
        form_token: post.signed_id(purpose: :comment_form),
        rendered_at: signed_rendered_at(10.seconds.ago)
      }
    end

    def with_turnstile_enabled
      ENV["TURNSTILE_ENABLED"] = "true"
      yield
    ensure
      ENV.delete("TURNSTILE_ENABLED")
    end
end
