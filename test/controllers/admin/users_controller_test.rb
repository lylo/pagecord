require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)

    login_as @user
  end

  test "should get index" do
    get admin_users_url
    assert_response :success
  end

  test "should search users by email" do
    user1 = users(:vivian)
    user2 = users(:joel)

    get admin_users_path(search: "vivian")

    assert_response :success
    assert_includes @response.body, user1.email
    assert_not_includes @response.body, user2.email
  end

  test "should search users by subdomain" do
    user1 = users(:vivian)
    user2 = users(:joel)

    get admin_users_path(search: user1.blog.subdomain)

    assert_response :success
    assert_includes @response.body, user1.blog.subdomain
    assert_not_includes @response.body, user2.blog.subdomain
  end

  test "should search users by custom domain" do
    user1 = users(:annie)
    user2 = users(:joel)

    get admin_users_path(search: "annie.blog")

    assert_response :success
    assert_includes @response.body, user1.email
    assert_not_includes @response.body, user2.email
  end

  test "should handle empty search parameter" do
    get admin_users_path(search: "")

    assert_response :success
    assert_includes @response.body, users(:vivian).email
    assert_includes @response.body, users(:joel).email
  end

  test "should return empty results for non-matching search" do
    get admin_users_path(search: "nonexistent@example.com")

    assert_response :success
    assert_not_includes @response.body, users(:vivian).email
    assert_not_includes @response.body, users(:joel).email
  end

  test "should filter by paid status" do
    get admin_users_path, params: { status: "paid" }
    assert_response :success

    assert_select "span", text: "Paid"
    assert_select "div", text: /results?/
  end

  test "should filter by comped status" do
    users(:joel).subscription.update!(plan: :complimentary)

    get admin_users_path, params: { status: "comped" }
    assert_response :success

    assert_select "span", text: "Comped"
    assert_select "td", text: /joel/
  end

  test "should combine search and status filters" do
    get admin_users_path, params: { search: "joel", status: "paid" }
    assert_response :success

    assert_select "a", text: /Paid/
    assert_select "div", text: /results?/
  end

  test "should preserve status filter when searching" do
    get admin_users_path, params: { status: "paid" }
    assert_response :success

    assert_select "input[type='hidden'][name='status'][value='paid']"
  end

  test "should show clickable stats summary links when no filter is active" do
    get admin_users_path
    assert_response :success

    assert_select "a[href='#{admin_users_path(status: "paid")}']"
    assert_select "a[href='#{admin_users_path(status: "comped")}']"
  end

  test "should highlight active filter in stats summary" do
    get admin_users_path, params: { status: "paid" }
    assert_response :success

    assert_select "a[href='#{admin_users_path}']", text: /Users/
  end

  test "should require admin access" do
    non_admin = users(:vivian)
    login_as non_admin

    get admin_users_path
    assert_redirected_to root_path
  end

  test "should show correct status labels in table" do
    get admin_users_path
    assert_response :success

    assert_select "td", text: "Premium"
    assert_select "td", text: "Free"
  end

  test "should handle empty search results with status filter" do
    get admin_users_path, params: { search: "nonexistent", status: "paid" }
    assert_response :success

    assert_select "span", text: "Paid"
    assert_select "div", text: /0 results/
  end

  test "should render blog rows with post counts" do
    get admin_users_path
    assert_response :success

    assert_select "th", text: "User"
    assert_select "th", text: "Blogs"
    assert_select "span", text: /posts?/
  end

  test "should discard regular user" do
    user = users(:vivian)
    assert_difference("User.kept.count", -1) do
      delete admin_user_url(user)
    end

    assert_redirected_to admin_users_path
    assert_equal "User was successfully discarded", flash[:notice]
    assert user.reload.discarded?
  end

  test "should restore user" do
    user = users(:vivian)
    user.discard!

    assert_difference("User.kept.count", 1) do
      post restore_admin_user_path(user)
    end

    assert_redirected_to admin_users_path
    assert_equal "User was successfully restored", flash[:notice]
    assert_not user.reload.discarded?
  end

  test "should touch all blogs when restoring user" do
    user = users(:annie)
    second_blog = user.blogs.create!(subdomain: "anniecache")
    old_time = 2.days.ago
    user.blogs.update_all(updated_at: old_time)
    user.discard!

    post restore_admin_user_path(user)

    assert_redirected_to admin_users_path
    assert_operator user.blog.reload.updated_at, :>, old_time
    assert_operator second_blog.reload.updated_at, :>, old_time
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
            blogs_attributes: [ { subdomain: "newuser" } ]
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
            blogs_attributes: [ { subdomain: "test.test" } ]
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
          blogs_attributes: [ { subdomain: "verification" } ]
        }
      }
    end
  end

  test "show renders feature fields as an array" do
    user = users(:vivian)

    get admin_user_url(user)

    assert_response :success
    assert_select "input[type='hidden'][name='user[features][]'][value='']"
    assert_select "input[type='checkbox'][name='user[features][]'][value='multiple_blogs']"
  end

  test "should add a feature to user" do
    user = users(:vivian)

    patch admin_user_url(user), params: {
      user: { features: [ "", "multiple_blogs" ] }
    }

    assert_redirected_to admin_user_path(user)
    assert_includes user.reload.features, "multiple_blogs"
  end

  test "should remove all features from user" do
    user = users(:vivian)
    user.update!(features: [ "multiple_blogs" ])

    patch admin_user_url(user), params: {
      user: { features: [ "" ] }
    }

    assert_redirected_to admin_user_path(user)
    assert_empty user.reload.features
  end

  test "should update user trial_ends_at" do
    user = users(:vivian)
    new_trial_date = 30.days.from_now.to_date

    patch admin_user_url(user), params: {
      user: { trial_ends_at: new_trial_date }
    }

    assert_redirected_to admin_user_path(user)
    assert_equal "User was successfully updated.", flash[:notice]
    assert_equal new_trial_date, user.reload.trial_ends_at
  end
end
