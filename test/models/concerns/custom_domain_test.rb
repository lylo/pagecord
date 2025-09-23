require "test_helper"

class CustomDomainTest < ActiveSupport::TestCase
  def setup
    @blog = blogs(:joel)
  end

  test "find_by_domain_with_www_fallback should find exact match first" do
    @blog.update!(custom_domain: "example.com")

    result = Blog.find_by_domain_with_www_fallback("example.com")
    assert_equal @blog, result
  end

  test "find_by_domain_with_www_fallback should find www variant for root domain" do
    @blog.update!(custom_domain: "www.example.com")

    result = Blog.find_by_domain_with_www_fallback("example.com")
    assert_equal @blog, result
  end

  test "find_by_domain_with_www_fallback should find root variant for www domain" do
    @blog.update!(custom_domain: "example.com")

    result = Blog.find_by_domain_with_www_fallback("www.example.com")
    assert_equal @blog, result
  end

  test "find_by_domain_with_www_fallback should not check www variant for subdomains" do
    @blog.update!(custom_domain: "www.blog.example.com")

    result = Blog.find_by_domain_with_www_fallback("blog.example.com")
    assert_nil result
  end

  test "find_by_domain_with_www_fallback should not check root variant for non-www subdomains" do
    @blog.update!(custom_domain: "api.example.com")

    result = Blog.find_by_domain_with_www_fallback("www.api.example.com")
    assert_nil result
  end

  test "find_by_domain_with_www_fallback should return nil for blank domain" do
    result = Blog.find_by_domain_with_www_fallback("")
    assert_nil result

    result = Blog.find_by_domain_with_www_fallback(nil)
    assert_nil result
  end

  test "find_by_domain_with_www_fallback should return nil when no match found" do
    result = Blog.find_by_domain_with_www_fallback("nonexistent.com")
    assert_nil result
  end

  test "find_by_domain_with_www_fallback should handle URLs with protocol" do
    @blog.update!(custom_domain: "example.com")

    result = Blog.find_by_domain_with_www_fallback("https://www.example.com")
    assert_equal @blog, result
  end
end
