require "test_helper"

class User::Screening::AccuracyTest < ActiveSupport::TestCase
  setup do
    @accuracy = User::Screening::Accuracy.new
  end

  test "counts confirmed spam that passed screening as missed spam" do
    AccountTombstone.create!(reason: :spam, failed_checks: { cleantalk: "FORBIDDEN BL" }, signed_up_at: 2.days.ago, deleted_at: 1.day.ago)
    AccountTombstone.create!(reason: :spam, failed_checks: {}, signed_up_at: 2.days.ago, deleted_at: 1.day.ago)
    AccountTombstone.create!(reason: :spam, failed_checks: nil, signed_up_at: 2.days.ago, deleted_at: 1.day.ago)

    assert_equal 2, @accuracy.reviewed_count
    assert_equal 1, @accuracy.missed_spam.size
  end

  test "counts blogs marked not spam that failed screening as false positives" do
    users(:annie).create_screening!(failed_checks: { cleantalk: "FORBIDDEN BL" })
    users(:vivian).create_screening!
    Blog.update_all(reviewed_at: Time.current)

    assert_equal 2, @accuracy.reviewed_count
    assert_equal [ users(:annie) ], @accuracy.false_positives.map(&:user)
  end
end
