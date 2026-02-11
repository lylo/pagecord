require "test_helper"

class Blog::ContactMessageTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
  end

  test "validates presence of name" do
    message = Blog::ContactMessage.new(blog: @blog, email: "test@example.com", message: "Hello")
    assert_not message.valid?
    assert_includes message.errors[:name], "can't be blank"
  end

  test "validates presence of email" do
    message = Blog::ContactMessage.new(blog: @blog, name: "Test", message: "Hello")
    assert_not message.valid?
    assert_includes message.errors[:email], "can't be blank"
  end

  test "validates email format" do
    message = Blog::ContactMessage.new(blog: @blog, name: "Test", email: "invalid", message: "Hello")
    assert_not message.valid?
    assert_includes message.errors[:email], "is invalid"
  end

  test "validates presence of message" do
    message = Blog::ContactMessage.new(blog: @blog, name: "Test", email: "test@example.com")
    assert_not message.valid?
    assert_includes message.errors[:message], "can't be blank"
  end

  test "creates valid contact message" do
    message = Blog::ContactMessage.new(
      blog: @blog,
      name: "Test User",
      email: "test@example.com",
      message: "Hello, this is a test message."
    )
    assert message.valid?
    assert message.save
  end

  test "belongs to blog" do
    message = Blog::ContactMessage.new(
      blog: @blog,
      name: "Test",
      email: "test@example.com",
      message: "Hello"
    )
    message.save!

    assert_equal @blog, message.blog
    assert_includes @blog.contact_messages, message
  end
end
