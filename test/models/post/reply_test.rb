require "test_helper"

class Post::ReplyTest < ActiveSupport::TestCase
  def setup
    @post = posts(:one)
    @reply = Post::Reply.new(
      post: @post,
      name: "Test User",
      email: "test@example.com",
      subject: "Test Subject",
      message: "This is a test message."
    )
  end

  test "valid reply" do
    assert @reply.valid?
  end

  test "invalid without name" do
    @reply.name = ""
    assert_not @reply.valid?
    assert_includes @reply.errors[:name], "can't be blank"
  end

  test "invalid without email" do
    @reply.email = ""
    assert_not @reply.valid?
    assert_includes @reply.errors[:email], "can't be blank"
  end

  test "invalid with improperly formatted email" do
    @reply.email = "invalid-email"
    assert_not @reply.valid?
    assert_includes @reply.errors[:email], "is invalid"
  end

  test "invalid without subject" do
    @reply.subject = ""
    assert_not @reply.valid?
    assert_includes @reply.errors[:subject], "can't be blank"
  end

  test "invalid without message" do
    @reply.message = ""
    assert_not @reply.valid?
    assert_includes @reply.errors[:message], "can't be blank"
  end
end
