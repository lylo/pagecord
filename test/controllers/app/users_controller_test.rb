require "test_helper"

class App::UsersControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "delete account" do
    assert_performed_jobs 1 do
      assert_difference("User.kept.count", -1) do
        delete app_user_url(@user)
      end
    end

    assert_redirected_to root_url
    assert_not User.kept.exists?(@user.id)
    assert User.exists?(@user.id) # soft delete
  end

  test "should update user bio" do
    patch app_user_url(@user), params: { user: { bio: "New bio" } }, as: :turbo_stream

    assert_response :success
    assert_equal "New bio", @user.reload.bio.to_plain_text
  end

  test "should update user custom domain" do
    patch app_user_url(@user), params: { user: { custom_domain: "newdomain.com" } }, as: :turbo_stream

    assert_response :success
    assert_equal "newdomain.com", @user.reload.custom_domain
  end

  test "should call hatchbox when adding custom domain" do
    assert_performed_jobs 1 do
      patch app_user_url(@user), params: { user: { custom_domain: "newdomain.com" } }, as: :turbo_stream
    end
  end

  test "should call hatchbox when removing custom domain" do
    user = users(:annie)
    login_as user

    assert_performed_jobs 1 do
      patch app_user_url(user), params: { user: { custom_domain: "" } }, as: :turbo_stream
    end
  end

  test "should not call hatchbox if nil custom domain is changed to empty string" do
    assert_performed_jobs 0 do
      patch app_user_url(@user), params: { user: { custom_domain: "" } }, as: :turbo_stream
    end
  end

  test "should not call hatchbox if custom domain is changed to same value" do
    assert_performed_jobs 0 do
      patch app_user_url(users(:annie)), params: { user: { custom_domain: users(:annie).custom_domain } }, as: :turbo_stream
    end
  end

  test "should raise an error after 5 custom domain changes" do
    user = users(:annie)

    (1..5).each do |i|
      user.custom_domain_changes.create!(custom_domain: "newdomain#{i}.com")
    end

    assert_raises do
      AddCustomDomainJob.perform_now(user.id, "newdomain6.com")
    end
  end
end
