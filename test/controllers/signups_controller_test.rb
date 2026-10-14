require "test_helper"

class SignupsControllerTest < ActionDispatch::IntegrationTest
  test "should create user and redirect to posts path" do
    assert_difference("User.count") do
      assert_emails 1 do
        post signups_url, params: { user: { email: "test@example.com", blogs_attributes: [ { subdomain: "testuser" } ] }, rendered_at: signed_rendered_at }
      end
    end

    assert_redirected_to signups_thanks_path

    assert_equal "testuser", User.last.blog.subdomain
    assert_equal "test@example.com", User.last.email
    assert_not User.last.marketing_consent
  end

  test "a blog name from the home page is already written in the letter" do
    get new_signup_path, params: { title: "Harbour Light" }

    assert_select "input[name='user[blogs_attributes][0][title]'][value='Harbour Light']"
    assert_select "input[name='user[email]'][autofocus]"
  end

  test "invite-only signup form takes its code from the link" do
    Invitation.stubs(:required?).returns(true)

    get new_signup_url(code: "ABCD1234")

    assert_select "input[name=invitation_code][value=ABCD1234]"
    assert_select ".letter-stamp__code", "ABCD1234"
  end

  test "invite-only signup needs an available invite code" do
    Invitation.stubs(:required?).returns(true)

    assert_no_difference("User.count") do
      post signups_url, params: { user: { email: "test@example.com", blogs_attributes: [ { subdomain: "testuser" } ] }, rendered_at: signed_rendered_at }
    end
    assert_response :unprocessable_entity

    assert_no_difference("User.count") do
      post signups_url, params: { invitation_code: invitations(:redeemed).code, user: { email: "test@example.com", blogs_attributes: [ { subdomain: "testuser" } ] }, rendered_at: signed_rendered_at }
    end
    assert_response :unprocessable_entity
  end

  test "invite-only signup refuses a list of codes in one request" do
    Invitation.stubs(:required?).returns(true)

    assert_no_difference("User.count") do
      post signups_url, params: { invitation_code: [ "WRONG23456", invitations(:unused).code ], user: { email: "test@example.com", blogs_attributes: [ { subdomain: "testuser" } ] }, rendered_at: signed_rendered_at }
    end
    assert_response :unprocessable_entity
  end

  test "invite-only signup refuses a code redeemed by someone else mid-signup" do
    Invitation.stubs(:required?).returns(true)
    User.any_instance.stubs(:save).raises(ActiveRecord::StaleObjectError)

    assert_no_difference("User.count") do
      post signups_url, params: { invitation_code: invitations(:unused).code, user: { email: "test@example.com", blogs_attributes: [ { subdomain: "testuser" } ] }, rendered_at: signed_rendered_at }
    end
    assert_response :unprocessable_entity
  end

  test "invite-only signup with a code records the inviter and skips review" do
    Invitation.stubs(:required?).returns(true)
    assert_difference("User.count") do
      post signups_url, params: { invitation_code: invitations(:unused).code.downcase, user: { email: "test@example.com", blogs_attributes: [ { subdomain: "testuser" } ] }, rendered_at: signed_rendered_at }
    end

    user = User.last
    assert_equal users(:joel), user.invitation.inviter
    assert user.blog.reviewed_at.present?
  end

  test "signing up keeps the blog name as its title" do
    post signups_url, params: { user: { email: "test@example.com", blogs_attributes: [ { title: "Harbour Light", subdomain: "harbourlight" } ] }, rendered_at: signed_rendered_at }

    assert_equal "Harbour Light", User.last.blog.title
  end

  test "a taken subdomain keeps the letter filled in and says so" do
    post signups_url, params: { user: { email: "test@example.com", blogs_attributes: [ { title: "Joel Again", subdomain: blogs(:joel).subdomain } ] }, rendered_at: signed_rendered_at }

    assert_response :unprocessable_entity
    assert_select "input[name='user[blogs_attributes][0][title]'][value='Joel Again']"
    assert_select ".letter-note", /taken/
  end

  test "a taken email offers to sign in" do
    post signups_url, params: { user: { email: users(:joel).email, blogs_attributes: [ { subdomain: "newblog" } ] }, rendered_at: signed_rendered_at }

    assert_select ".letter-note a[href=?]", login_path
    assert_select "p input[name='user[email]']", 1
    assert_select "input[name='user[email]'][autofocus]"
    assert_select "input[name='user[blogs_attributes][0][title]'][autofocus]", 0
  end

  test "a validation failure is logged without the email address" do
    io = StringIO.new
    previous = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)
    post signups_url, params: { user: { email: users(:joel).email, blogs_attributes: [ { subdomain: blogs(:joel).subdomain } ] }, rendered_at: signed_rendered_at }
    Rails.logger = previous

    assert_equal "blogs.subdomain taken, email taken", io.string[/Signup validation failed: (.*)/, 1]
    assert_not_includes io.string, users(:joel).email
  end

  test "should preserve signup attribution for plausible goal page" do
    get root_url, params: {
      utm_source: "reddit",
      utm_campaign: "obsidian_blog",
      utm_content: "ignored"
    }

    assert_difference("User.count") do
      assert_emails 1 do
        post signups_url, params: {
          user: { email: "test@example.com", blogs_attributes: [ { subdomain: "testuser" } ] },
          rendered_at: signed_rendered_at
        }
      end
    end

    assert_redirected_to signups_thanks_path(utm_source: "reddit", utm_campaign: "obsidian_blog")

    assert_difference("User.count") do
      assert_emails 1 do
        post signups_url, params: {
          user: { email: "second@example.com", blogs_attributes: [ { subdomain: "seconduser" } ] },
          rendered_at: signed_rendered_at
        }
      end
    end

    assert_redirected_to signups_thanks_path
  end

  test "should keep signup attribution after validation failure" do
    get root_url, params: { utm_source: "reddit", utm_campaign: "obsidian_blog" }

    assert_no_difference("User.count") do
      assert_emails 0 do
        post signups_url, params: {
          user: { email: "test@example.com", blogs_attributes: [ { subdomain: " invalid.subdomain" } ] },
          rendered_at: signed_rendered_at
        }
      end
    end

    assert_response :unprocessable_entity

    assert_difference("User.count") do
      assert_emails 1 do
        post signups_url, params: {
          user: { email: "test@example.com", blogs_attributes: [ { subdomain: "testuser" } ] },
          rendered_at: signed_rendered_at
        }
      end
    end

    assert_redirected_to signups_thanks_path(utm_source: "reddit", utm_campaign: "obsidian_blog")
  end

  test "should capture signup attribution fields" do
    assert_difference("User.count") do
      post signups_url, params: { user: { email: "test@example.com", blogs_attributes: [ { subdomain: "testuser" } ], signup_referrer: "https://pagecord.com/pagecord_vs_substack", signup_source_note: "Hacker News" }, rendered_at: signed_rendered_at }
    end

    assert_equal "https://pagecord.com/pagecord_vs_substack", User.last.signup_referrer
    assert_equal "Hacker News", User.last.signup_source_note
  end

  test "should create user with timezone" do
    assert_difference("User.count") do
      assert_emails 1 do
        post signups_url, params: { user: { email: "test@example.com", blogs_attributes: [ { subdomain: "testuser" } ], marketing_consent: true, timezone: "Europe/Warsaw" }, rendered_at: signed_rendered_at }
      end
    end

    assert_redirected_to signups_thanks_path
    assert User.last.marketing_consent
    assert_equal "Warsaw", User.last.timezone
  end

  test "should not create user from banned timezone" do
    assert_no_difference("User.count") do
      assert_emails 0 do
        previous_env = ENV["BANNED_TIMEZONES"]
        ENV["BANNED_TIMEZONES"] = "Chennai"
        post signups_url, params: { user: { email: "test@example.com", blogs_attributes: [ { subdomain: "testuser" } ], marketing_consent: true, timezone: "Asia/Kolkata" }, rendered_at: signed_rendered_at }
        ENV["BANNED_TIMEZONES"] = previous_env
      end
    end

    assert_response :unprocessable_entity
    assert_includes @response.body, "Signups from your region are paused"
    assert_includes @response.body, "mailto:hello@pagecord.com"
  end

  test "should screen the new account" do
    ENV["CLEANTALK_AUTH_KEY"] = "test-key"
    CleanTalk.expects(:check_newuser).with(has_entries(email: "test@example.com", ip: "127.0.0.1")).returns({ "allow" => 0, "codes" => "FORBIDDEN BL" })

    perform_enqueued_jobs(only: ScreenUserJob) do
      post signups_url, params: { user: { email: "test@example.com", blogs_attributes: [ { subdomain: "testuser" } ] }, rendered_at: signed_rendered_at }
    end

    assert_redirected_to signups_thanks_path
    assert User.last.screening_failed?
  ensure
    ENV.delete("CLEANTALK_AUTH_KEY")
  end

  test "should not create user with invalid subdomain" do
    assert_no_difference("User.count") do
      assert_emails 0 do
        post signups_url, params: { user: { email: "test@pagecord.com", blogs_attributes: [ { subdomain: " invalid.subdomain" } ] }, rendered_at: signed_rendered_at }
      end
    end

    assert_response :unprocessable_entity
    assert_includes @response.body, "can only contain letters and numbers"
  end

  test "should not create user if honeypot field is populated" do
    assert_no_difference("User.count") do
      post signups_url, params: { email_confirmation: "test@example.com", user: { email: "test@example.com", blogs_attributes: [ { subdomain: "testuser" } ] }, rendered_at: signed_rendered_at }
    end

    assert_response :unprocessable_entity
    assert_includes @response.body, "There&#39;s an issue signing you up"
  end

  test "should not create user if form rendered and submitted within 5 seconds" do
    assert_no_difference("User.count") do
      post signups_url, params: { user: { email: "test@example.com", blogs_attributes: [ { subdomain: "testuser" } ] }, rendered_at: signed_rendered_at(1.second.ago) }
    end

    assert_response :unprocessable_entity
    assert_includes @response.body, "There&#39;s an issue signing you up"
  end
end
