require "test_helper"

class ActiveStorageInitializerTest < ActiveSupport::TestCase
  test "libvips refuses untrusted loaders" do
    assert_raises(Vips::Error) { Vips::Image.new_from_buffer(%(<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>), "") }
  end
end
