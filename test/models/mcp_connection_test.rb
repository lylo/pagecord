require "test_helper"

class McpConnectionTest < ActiveSupport::TestCase
  test "a code is exchanged once for a token" do
    connection = mcp_connections(:joel_pending)
    code = connection.issue_code!

    assert_equal connection, McpConnection.find_by_code(code)

    token = connection.issue_token!

    assert_nil McpConnection.find_by_code(code)
    assert_equal connection, McpConnection.find_by_token(token)
  end

  test "issuing a token replaces the previous one" do
    mcp_connections(:joel_claude).issue_token!

    assert_nil McpConnection.find_by_token("test_mcp_token")
  end

  test "expired codes are not found" do
    connection = mcp_connections(:joel_pending)
    code = connection.issue_code!

    travel McpConnection::CODE_LIFETIME + 1.second do
      assert_nil McpConnection.find_by_code(code)
    end
  end

  test "tokens stop working when the blog or its account is discarded" do
    users(:joel).discard!
    assert_nil McpConnection.find_by_token("test_mcp_token")

    users(:joel).undiscard!
    blogs(:joel).discard!
    assert_nil McpConnection.find_by_token("test_mcp_token")
  end

  test "starting a consent sweeps the blog's abandoned ones" do
    abandoned = mcp_connections(:joel_pending)

    travel McpConnection::CODE_LIFETIME + 1.second do
      abandoned.dup.issue_code!
    end

    assert_not McpConnection.exists?(abandoned.id)
    assert McpConnection.exists?(mcp_connections(:joel_claude).id)
  end

  test "verifies an S256 code challenge" do
    connection = mcp_connections(:joel_pending)

    assert connection.verifies?("test_verifier")
    assert_not connection.verifies?("wrong_verifier")
  end
end
