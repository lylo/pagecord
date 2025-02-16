require "test_helper"

class BlogTest < ActiveSupport::TestCase
  def setup
    @blog = blogs(:joel)
  end

  test "should validate length of name" do
    @blog.name = "a" * 21
    assert_not @blog.valid?

    @blog.name = "a"
    assert_not @blog.valid?

    @blog.name = "aaaa"
    assert @blog.valid?
  end

  test "should validate presence of name" do
    @blog.name = ""
    assert_not @blog.valid?
  end

  test "should validate uniqueness of name" do
    @blog.name = "vivian"
    assert_not @blog.valid?
  end

  test "should validate format of name" do
    @blog.name = "abcdef-"
    assert_not @blog.valid?

    @blog.name = "%12312"
    assert_not @blog.valid?

    @blog.name = "abcdef_1234"
    assert @blog.valid?
  end

  test "should validate length of bio" do
    @blog.bio = "a" * 513
    assert_not @blog.valid?
  end

  test "should store name in lowercase" do
    @blog.name = "JOEL"
    @blog.save
    assert_equal "joel", @blog.name
  end

  test "should generate unique delivery email" do
    user = User.create!(email: "newuser@newuser.com", blog: Blog.new(name: "newuser"))
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

  test "should normalize custom domain" do
    @blog.custom_domain = ""
    @blog.save!

    assert_nil @blog.reload.custom_domain
  end

  test "should destroy post digests on destroy" do
    assert_difference "PostDigest.count", -1 do
      @blog.destroy
    end
  end

  test "blog title" do
    blog = blogs(:joel)
    assert_equal "Posts from @joel", blog.display_title

    blog.title = "My blog"
    assert_equal "My blog", blog.display_title
  end
end
