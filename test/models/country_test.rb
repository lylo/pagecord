require "test_helper"

class CountryTest < ActiveSupport::TestCase
  test "returns name for known country code" do
    assert_equal "United States", Country.new("US").name
    assert_equal "United Kingdom", Country.new("GB").name
    assert_equal "Germany", Country.new("DE").name
    assert_equal "Japan", Country.new("JP").name
  end

  test "returns code for unknown country" do
    assert_equal "ZZ", Country.new("ZZ").name
    assert_equal "AA", Country.new("AA").name
  end

  test "returns Unknown for nil or XX code" do
    assert_equal "Unknown", Country.new(nil).name
    assert_equal "Unknown", Country.new("XX").name
    assert_equal "Unknown", Country.new("T1").name  # Tor exit node
  end

  test "handles lowercase country codes" do
    assert_equal "United States", Country.new("us").name
    assert_equal "Germany", Country.new("de").name
  end

  test "returns flag emoji for known countries" do
    # Flag emojis are regional indicator symbols
    assert_equal "\u{1F1FA}\u{1F1F8}", Country.new("US").flag  # US flag
    assert_equal "\u{1F1EC}\u{1F1E7}", Country.new("GB").flag  # UK flag
    assert_equal "\u{1F1E9}\u{1F1EA}", Country.new("DE").flag  # German flag
  end

  test "returns globe emoji for unknown countries" do
    assert_equal "\u{1F30D}", Country.new(nil).flag
    assert_equal "\u{1F30D}", Country.new("XX").flag
  end

  test "generates flag for unlisted but valid country codes" do
    # Should generate flag from code even if not in COUNTRIES hash
    flag = Country.new("ZZ").flag
    # ZZ should generate a flag emoji (even though it's not a real country)
    assert flag.present?
  end

  test "unknown? returns true for nil, XX, and T1" do
    assert Country.new(nil).unknown?
    assert Country.new("XX").unknown?
    assert Country.new("T1").unknown?
    assert_not Country.new("US").unknown?
  end
end
