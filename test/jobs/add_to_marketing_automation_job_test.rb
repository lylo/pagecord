require "test_helper"
require "mocha/minitest"

class AddToMarketingAutomationJobTest < ActiveJob::TestCase
  def setup
    @user = users(:joel)
  end

  test "does not call LoopsSdk::Contacts.create in non-production environments" do
    Rails.env.stubs(:production?).returns(false)
    LoopsSdk::Contacts.expects(:create).never
    AddToMarketingAutomationJob.perform_now(@user.id)
  end

  test "calls LoopsSdk::Contacts.create in production environment" do
    Rails.env.stubs(:production?).returns(true)
    LoopsSdk::Contacts.expects(:create).with(
      email: @user.email,
      properties: {
        username: @user.username,
        deliveryEmail: @user.blog.delivery_email
      },
      mailing_lists: {
        cm3bk30v201in0ml49wza278w: @user.marketing_consent
      }
    ).returns({ "success" => true })

    AddToMarketingAutomationJob.perform_now(@user.id)
  end

  test "raises an error if LoopsSdk::Contacts.create fails in production" do
    Rails.env.stubs(:production?).returns(true)
    LoopsSdk::Contacts.expects(:create).returns({ "success" => false })
    assert_raises(RuntimeError, "LoopsSdk::Contacts.create failed: {\"success\"=>false}") do
      AddToMarketingAutomationJob.perform_now(@user.id)
    end
  end
end
