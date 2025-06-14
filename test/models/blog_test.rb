require "test_helper"

class BlogTest < ActiveSupport::TestCase
  def setup
    @blog = blogs(:joel)
  end

  test "should validate length of subdomain" do
    @blog.subdomain = "a" * 21
    assert_not @blog.valid?

    @blog.subdomain = "a"
    assert_not @blog.valid?

    @blog.subdomain = "aaaa"
    assert @blog.valid?
  end

  test "should validate presence of subdomain" do
    @blog.subdomain = ""
    assert_not @blog.valid?
  end

  test "should validate uniqueness of subdomain" do
    @blog.subdomain = "vivian"
    assert_not @blog.valid?
  end

  test "should reserve subdomain" do
    @blog.subdomain = "pagecord"
    assert_not @blog.valid?
  end

  test "should validate format of subdomain" do
    @blog.subdomain = "abcdef-"
    assert_not @blog.valid?

    @blog.subdomain = "%12312"
    assert_not @blog.valid?

    @blog.subdomain = "abcdef_1234"
    assert_not @blog.valid?

    @blog.subdomain = "abcdef1234"
    assert @blog.valid?
  end

  test "should validate length of bio" do
    @blog.bio = "a" * 513
    assert_not @blog.valid?
  end

  test "should store subdomain in lowercase" do
    @blog.subdomain = "JOEL"
    @blog.save
    assert_equal "joel", @blog.subdomain
  end

  test "should generate unique delivery email" do
    user = User.create!(email: "newuser@newuser.com", blog: Blog.new(subdomain: "newuser"))
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

  test "should validate google site verification" do
    @blog.google_site_verification = "GzmHXW-PA_FXh29Dp31_cgsIx6ZY_h9OgR6r8DZ0I44"
    assert @blog.valid?

    @blog.google_site_verification = "abc123_DEF-456"
    assert @blog.valid?

    @blog.google_site_verification = "simple123"
    assert @blog.valid?

    @blog.google_site_verification = ""
    assert @blog.valid?

    @blog.google_site_verification = nil
    assert @blog.valid?

    @blog.google_site_verification = "invalid code with spaces"
    assert_not @blog.valid?
    assert_includes @blog.errors.full_messages, "Google site verification can only contain letters, numbers, underscores, and hyphens"
  end
end
