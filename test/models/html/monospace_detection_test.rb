require "test_helper"

class Html::MonospaceDetectionTest < ActiveSupport::TestCase

  test "should convert monospace style tag to code block" do
    html = "<div><span style=\"font-family: menlo, consolas, monospace\">this is monospace</span></div>"
    transformed_html = Html::MonospaceDetection.new.transform(html)
    assert_equal "<div><code>this is monospace</code></div>", transformed_html
  end

  test "should convert monospace font tag to code block" do
    html = "<div><font face=\"monospace, incolsolata\">this is monospace</font></div>"
    transformed_html = Html::MonospaceDetection.new.transform(html)
    assert_equal "<div><code>this is monospace</code></div>", transformed_html
  end
end
