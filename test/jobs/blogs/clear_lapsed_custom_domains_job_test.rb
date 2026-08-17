require "test_helper"

class Blogs::ClearLapsedCustomDomainsJobTest < ActiveJob::TestCase
  test "clears custom domain when the owner has lost access" do
    blog = blogs(:vivian)
    blog.update!(custom_domain: "gone.example.com")
    assert_not blog.user.custom_domain_access?

    Blogs::ClearLapsedCustomDomainsJob.perform_now

    assert_nil blog.reload.custom_domain
  end

  test "keeps custom domain for active subscribers" do
    blog = blogs(:annie)
    assert blog.user.custom_domain_access?

    Blogs::ClearLapsedCustomDomainsJob.perform_now

    assert_equal "annie.blog", blog.reload.custom_domain
  end

  test "enqueues RemoveCustomDomainJob for each cleared domain" do
    blog = blogs(:vivian)
    blog.update!(custom_domain: "gone.example.com")

    assert_enqueued_with(job: RemoveCustomDomainJob, args: [ blog.id, "gone.example.com" ]) do
      Blogs::ClearLapsedCustomDomainsJob.perform_now
    end
  end

  test "records a custom domain change when clearing" do
    blog = blogs(:vivian)
    blog.update!(custom_domain: "gone.example.com")

    assert_difference -> { blog.custom_domain_changes.count }, 1 do
      Blogs::ClearLapsedCustomDomainsJob.perform_now
    end
  end
end
