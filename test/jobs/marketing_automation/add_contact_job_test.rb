require "test_helper"
require "mocha/minitest"

class MarketingAutomation::AddContactJobTest < ActiveJob::TestCase
  def setup
    @user = users(:joel)
  end

  test "does not call LoopsSdk::Contacts.create in non-production environments" do
    Rails.env.stubs(:production?).returns(false)
    LoopsSdk::Contacts.expects(:create).never
    MarketingAutomation::AddContactJob.perform_now(@user.id)
  end

  test "calls LoopsSdk::Contacts.create in production environment" do
    Rails.env.stubs(:production?).returns(true)
    LoopsSdk::Contacts.expects(:create).with(
      email: @user.email,
      properties: {
        username: @user.blog.name,
        deliveryEmail: @user.blog.delivery_email
      },
      mailing_lists: {
        cm3bk30v201in0ml49wza278w: @user.marketing_consent
      }
    ).returns({ "success" => true })

    MarketingAutomation::AddContactJob.perform_now(@user.id)
  end

  test "should not raise an error if LoopsSdk::Contacts.create returns a 409" do
    Rails.env.stubs(:production?).returns(true)
    LoopsSdk::Contacts.expects(:create).raises(LoopsSdk::APIError.new(409, "Email already exists"))
    assert_nothing_raised do
      MarketingAutomation::AddContactJob.perform_now(@user.id)
    end
  end
end
