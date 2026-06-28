require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  test "should show log in page" do
    get login_url
    assert_response :success
  end

  test "should send verification email for valid credentials" do
    user = users(:joel)

    assert_emails 1 do
      post sessions_url, params: { user: { subdomain: user.blog.subdomain, email: user.email }, rendered_at: signed_rendered_at }
    end

    assert_redirected_to thanks_sessions_path
  end

  test "should send verification email for valid credentials with whitespace" do
    user = users(:joel)

    assert_emails 1 do
      post sessions_url, params: { user: { subdomain: "#{user.blog.subdomain} ", email: "#{user.email} " }, rendered_at: signed_rendered_at }
    end

    assert_redirected_to thanks_sessions_path
  end

  test "should send verification email for valid credentials regardless of case" do
    user = users(:joel)

    assert_emails 1 do
      post sessions_url, params: { user: { subdomain: user.blog.subdomain.upcase, email: user.email.upcase }, rendered_at: signed_rendered_at }
    end

    assert_redirected_to thanks_sessions_path
  end

  test "should not send verification email for invalid credentials" do
    assert_emails 0 do
      post sessions_url, params: { user: { subdomain: "nope", email: "nope@nope.com" }, rendered_at: signed_rendered_at }
    end

    assert_redirected_to thanks_sessions_path
  end

  test "should destroy session" do
    delete logout_url
    assert_redirected_to root_path
  end

  test "should redirect to app root if already logged in" do
    login_as users(:joel)

    get login_url
    assert_redirected_to app_root_path
  end

  test "login with correct password" do
    user = users(:joel)
    user.update!(password: "TestPass1234", password_confirmation: "TestPass1234")

    post sessions_url, params: {
      user: { subdomain: user.blog.subdomain, password: "TestPass1234" },
      rendered_at: signed_rendered_at
    }

    assert_redirected_to app_root_path
    assert_equal user.id, session[:user_id]
  end

  test "login session cookie is scoped to the app host" do
    user = users(:joel)
    user.update!(password: "TestPass1234", password_confirmation: "TestPass1234")

    post sessions_url, params: {
      user: { subdomain: user.blog.subdomain, password: "TestPass1234" },
      rendered_at: signed_rendered_at
    }

    session_cookie = set_cookie_headers.grep(/\A_pagecord_v3=/).join("\n")

    assert session_cookie.present?
    assert_no_match(/;\s*domain=/i, session_cookie)
  end

  test "password login selects the matching blog" do
    user = users(:joel)
    second_blog = blogs(:joel_notes)
    user.update!(password: "TestPass1234", password_confirmation: "TestPass1234")

    post sessions_url, params: {
      user: { subdomain: second_blog.subdomain, password: "TestPass1234" },
      rendered_at: signed_rendered_at
    }

    assert_redirected_to app_root_path
    assert_equal user.id, session[:user_id]
    assert_equal second_blog.id, session[:current_blog_id]
  end

  test "email login verification defaults to first blog" do
    user = users(:joel)
    second_blog = blogs(:joel_notes)

    assert_emails 1 do
      post sessions_url, params: {
        user: { subdomain: second_blog.subdomain, email: user.email },
        rendered_at: signed_rendered_at
      }
    end
    get verify_access_request_url(user.access_requests.last.token_digest)

    assert_redirected_to app_posts_path
    assert_equal user.id, session[:user_id]
    assert_nil session[:current_blog_id]
  end

  test "login with password does not authenticate unverified user" do
    user = users(:elliot)
    user.update!(password: "TestPass1234", password_confirmation: "TestPass1234")

    assert_no_emails do
      post sessions_url, params: {
        user: { subdomain: user.blog.subdomain, password: "TestPass1234" },
        rendered_at: signed_rendered_at
      }
    end

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test "login with wrong password" do
    user = users(:joel)
    user.update!(password: "TestPass1234", password_confirmation: "TestPass1234")

    post sessions_url, params: {
      user: { subdomain: user.blog.subdomain, password: "wrongpassword" },
      rendered_at: signed_rendered_at
    }

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  private

    def set_cookie_headers
      Array(response.headers["Set-Cookie"]).flat_map { |header| header.to_s.split("\n") }
    end
end
