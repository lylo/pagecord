require "test_helper"

class Html::HeadingIdsTest < ActiveSupport::TestCase
  setup do
    @transformer = Html::HeadingIds.new
  end

  test "adds id to heading" do
    result = @transformer.transform("<h2>Introduction</h2>")
    assert_includes result, 'id="introduction"'
  end

  test "handles duplicate headings" do
    result = @transformer.transform("<h2>Intro</h2><h2>Intro</h2><h2>Intro</h2>")
    assert_includes result, 'id="intro"'
    assert_includes result, 'id="intro-1"'
    assert_includes result, 'id="intro-2"'
  end

  test "preserves existing ids" do
    result = @transformer.transform('<h2 id="custom">Heading</h2>')
    assert_includes result, 'id="custom"'
    assert_not_includes result, 'id="heading"'
  end

  test "skips empty headings" do
    result = @transformer.transform("<h2></h2><h2>   </h2>")
    assert_not_includes result, "id="
  end

  test "handles all heading levels" do
    html = "<h1>One</h1><h2>Two</h2><h3>Three</h3><h4>Four</h4><h5>Five</h5><h6>Six</h6>"
    result = @transformer.transform(html)
    %w[one two three four five six].each { |id| assert_includes result, "id=\"#{id}\"" }
  end

  test "returns blank html unchanged" do
    assert_equal "", @transformer.transform("")
    assert_nil @transformer.transform(nil)
  end
end
