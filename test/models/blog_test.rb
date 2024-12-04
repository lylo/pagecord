require "test_helper"

class BlogTest < ActiveSupport::TestCase
  def setup
    @blog = blogs(:joel)
  end
  test "should validate length of bio" do
    @blog.bio = "a" * 513
    assert_not @blog.valid?
  end

  test "should generate unique delivery email" do
    user = User.create!(username: "newuser", email: "newuser@newuser.com")
    assert user.blog.delivery_email.present?
    assert user.blog.delivery_email =~ /newuser_[a-zA-Z0-9]{8}@post.pagecord.com/
  end

  test "should allow valid custom domain" do
    @blog.custom_domain = "newdomain.com"

    assert @blog.valid?
  end

  test "should not allow invalid custom domain format" do
    @blog.custom_domain = "blah blah"

    assert_not @blog.valid?
  end

  test "should validate restricted custom domain" do
    @blog.custom_domain = "pagecord.com"

    assert_not @blog.valid?
    assert_includes @blog.errors.full_messages, "Custom domain is restricted"
  end

  test "should record custom domain change" do
    @blog.update!(custom_domain: "newdomain.com")

    assert @blog.valid?
    assert_equal 1, @blog.custom_domain_changes.count
  end
end
