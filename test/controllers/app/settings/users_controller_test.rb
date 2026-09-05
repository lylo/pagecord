require "test_helper"
require "mocha/minitest"

class App::Settings::UsersControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "delete account as subscriber schedules destroy and cancellation email jobs" do
    assert_enqueued_with(job: DestroyUserJob, args: [ @user.id ]) do
      assert_enqueued_with(job: SendCancellationEmailJob, args: [ @user.id, { subscriber: false } ]) do
        delete app_settings_user_url(@user)
      end
    end

    assert_redirected_to root_url
  end

  test "delete account as free user schedules destroy and cancellation email jobs" do
    free_user = users(:vivian)
    login_as free_user

    assert_enqueued_with(job: DestroyUserJob, args: [ free_user.id ]) do
      assert_enqueued_with(job: SendCancellationEmailJob, args: [ free_user.id, { subscriber: false } ]) do
        delete app_settings_user_url(free_user)
      end
    end

    assert_redirected_to root_url
  end

  test "delete account logs the blog and whether they were paying" do
    lines = billing_lines { delete app_settings_user_url(@user) }

    line = lines.find { |l| l.include?("event=account_deleted") }
    assert line, "expected an account_deleted line, got: #{lines.inspect}"
    assert_includes line, "blog=#{@user.blog.subdomain}"
    assert_includes line, "paid=true"
    assert_includes line, "source=app"
  end

  test "delete account of a free user records no plan or amount" do
    free_user = users(:vivian)
    login_as free_user

    lines = billing_lines { delete app_settings_user_url(free_user) }

    line = lines.find { |l| l.include?("event=account_deleted") }
    assert_includes line, "paid=false"
    assert_includes line, "blog=#{free_user.blog.subdomain}"
    assert_no_match(/amount=/, line)
  end

  private

    def billing_lines
      io = StringIO.new
      previous = Rails.logger
      Rails.logger = ActiveSupport::Logger.new(io)
      yield
      io.string.scan(/\[billing\].*/)
    ensure
      Rails.logger = previous
    end
end
