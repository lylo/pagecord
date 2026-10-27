require "test_helper"

class App::Onboardings::CompletionsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:saul)
    login_as @user
  end

  test "saves the bio and language, completes onboarding and opens Posts" do
    post app_onboarding_completion_path, params: { blog: { bio: "I write <3 about the sea", locale: "fr" } }

    assert_redirected_to app_posts_path
    assert @user.reload.onboarding_complete?
    assert_equal "I write <3 about the sea", @user.blog.bio.to_plain_text
    assert_equal "fr", @user.blog.locale
  end

  test "keeps line breaks in the bio" do
    post app_onboarding_completion_path, params: { blog: { bio: "one\r\ntwo" } }

    assert_equal "one\ntwo", @user.blog.reload.bio.to_plain_text
  end

  test "stays on the letter when the bio is too long" do
    post app_onboarding_completion_path, params: { blog: { bio: "a" * 501 } }

    assert_response :unprocessable_entity
    assert_select ".letter-note", text: /too long/
    assert_select "textarea[name=?]", "blog[bio]", text: "a" * 501
    assert_not @user.reload.onboarding_complete?
  end
end
