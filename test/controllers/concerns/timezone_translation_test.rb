require "test_helper"

class TimezoneTranslatiponTest < ActiveSupport::TestCase
  include TimezoneTranslation

  test "should convert IANA timezone to ActiveSupport timezone" do
    assert_equal "Warsaw", active_support_time_zone_from_iana("Europe/Warsaw")
  end

  test "should return nil for invalid timezone" do
    assert_nil active_support_time_zone_from_iana("Invalid/Timezone")
  end

  test "should convert legacy IANA timezone" do
    assert_equal "Chennai", active_support_time_zone_from_iana("Asia/Kolkata")
  end
end
