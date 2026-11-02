require "test_helper"

class CancellationTest < ActiveSupport::TestCase
  setup do
    @user = users(:annie)
    @cancellation = @user.cancellations.create!(kind: :account, reason: :not_writing, feedback: "Too busy")
  end

  test "restoring the account removes its exit reason" do
    @user.discard!

    assert_difference -> { Cancellation.count }, -1 do
      @user.undiscard!
    end
  end

  test "restoring the account keeps an earlier subscription cancellation" do
    @user.cancellations.create!(kind: :subscription, reason: :too_expensive)
    @user.discard!
    @user.undiscard!

    assert_equal [ "subscription" ], @user.cancellations.pluck(:kind)
  end

  test "purging the account keeps the reason but drops what they wrote" do
    @user.destroy!

    @cancellation.reload
    assert_nil @cancellation.user_id
    assert_nil @cancellation.feedback
    assert @cancellation.not_writing?
  end
end
