require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  # An anonymous visitor has no user_id, and find_by(id: nil) would query for a
  # row that cannot exist on every request the site serves.
  test "does not query for a user when nobody is signed in" do
    assert_equal 0, user_queries { get root_path }
  end

  test "loads the signed in user" do
    login_as users(:joel)

    assert_equal 1, user_queries { get root_path }
  end

  private

    def user_queries
      queries = 0

      subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        queries += 1 if payload[:sql].include?('FROM "users"') && payload[:name] != "SCHEMA"
      end

      yield
      queries
    ensure
      ActiveSupport::Notifications.unsubscribe(subscription)
    end
end
