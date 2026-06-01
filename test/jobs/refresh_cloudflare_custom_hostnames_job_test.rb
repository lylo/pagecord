require "test_helper"
require "mocha/minitest"

class RefreshCloudflareCustomHostnamesJobTest < ActiveJob::TestCase
  setup do
    @blog = blogs(:joel)
    @blog.update!(custom_domain: "example.com")
  end

  test "refreshes validation and requeues while hostnames are pending" do
    Rails.env.stubs(:production?).returns(true)
    CloudflareSaasApi.any_instance
      .expects(:refresh_domain_validation)
      .with("example.com")
      .returns([ { "id" => "root-id" } ])

    assert_enqueued_with(job: RefreshCloudflareCustomHostnamesJob, args: [ @blog.id, "example.com", 2 ]) do
      RefreshCloudflareCustomHostnamesJob.perform_now(@blog.id, "example.com")
    end
  end

  test "does not requeue when hostnames are active" do
    Rails.env.stubs(:production?).returns(true)
    CloudflareSaasApi.any_instance
      .expects(:refresh_domain_validation)
      .with("example.com")
      .returns([])

    assert_no_enqueued_jobs do
      RefreshCloudflareCustomHostnamesJob.perform_now(@blog.id, "example.com")
    end
  end

  test "does not refresh stale domains" do
    Rails.env.stubs(:production?).returns(true)
    @blog.update!(custom_domain: "new.example.com")
    CloudflareSaasApi.any_instance.expects(:refresh_domain_validation).never

    assert_no_enqueued_jobs do
      RefreshCloudflareCustomHostnamesJob.perform_now(@blog.id, "example.com")
    end
  end

  test "does not requeue after max attempts" do
    Rails.env.stubs(:production?).returns(true)
    CloudflareSaasApi.any_instance
      .expects(:refresh_domain_validation)
      .with("example.com")
      .returns([ { "id" => "root-id" } ])

    assert_no_enqueued_jobs do
      RefreshCloudflareCustomHostnamesJob.perform_now(@blog.id, "example.com", RefreshCloudflareCustomHostnamesJob::MAX_ATTEMPTS)
    end
  end

  test "add custom domain job schedules validation refresh in production" do
    Rails.env.stubs(:production?).returns(true)
    CloudflareSaasApi.any_instance
      .expects(:add_domain)
      .with("example.com")
      .returns([ { "id" => "root-id" } ])

    assert_enqueued_with(job: RefreshCloudflareCustomHostnamesJob, args: [ @blog.id, "example.com" ]) do
      AddCustomDomainJob.perform_now(@blog.id, "example.com")
    end
  end
end
