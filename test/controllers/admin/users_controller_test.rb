require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)

    login_as @user
  end

  test "should discard regular user" do
    user = users(:vivian)
    assert_difference("User.kept.count", -1) do
      delete admin_user_url(user)
    end

    assert_redirected_to admin_blogs_path
    assert_equal "User was successfully discarded", flash[:notice]
    assert user.reload.discarded?
  end

  test "should restore user" do
    user = users(:vivian)
    user.discard!

    assert_difference("User.kept.count", 1) do
      post restore_admin_user_path(user)
    end

    assert_redirected_to admin_blogs_path
    assert_equal "User was successfully restored", flash[:notice]
    assert_not user.reload.discarded?
  end

  test "should get new" do
    get new_admin_user_url
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count") do
      assert_difference("Blog.count") do
        post admin_users_url, params: {
          user: {
            email: "newuser@example.com",
            blog_attributes: {
              subdomain: "newuser"
            }
          }
        }
      end
    end

    assert_redirected_to admin_user_path(User.last)
    assert_equal "User was successfully created.", flash[:notice]

    user = User.find_by(email: "newuser@example.com")
    assert_not_nil user
    assert_equal "newuser", user.blog.subdomain
    assert_not user.verified?
  end

  test "should not create user with invalid data" do
    assert_no_difference("User.count") do
      assert_no_difference("Blog.count") do
        post admin_users_url, params: {
          user: {
            email: "test@example.com",
            blog_attributes: {
              subdomain: "test.test"
            }
          }
        }
      end
    end

    assert_response :unprocessable_entity
  end

  test "should deliver verification email when user is created" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      post admin_users_url, params: {
        user: {
          email: "verification@example.com",
          blog_attributes: {
            subdomain: "verification"
          }
        }
      }
    end
  end
end
