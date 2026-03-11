require "test_helper"

class PurgeUnattachedBlobsJobTest < ActiveJob::TestCase
  test "purges unattached blobs older than 24 hours" do
    old_blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("space.jpg").open, filename: "old.jpg")
    old_blob.update_columns(created_at: 25.hours.ago)

    recent_blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("space.jpg").open, filename: "recent.jpg")

    assert_enqueued_with(job: ActiveStorage::PurgeJob) do
      PurgeUnattachedBlobsJob.perform_now
    end

    # Only the old blob should be enqueued for purging
    assert_equal 1, enqueued_jobs.count { |j| j["job_class"] == "ActiveStorage::PurgeJob" }
  end

  test "does not purge attached blobs" do
    post = posts(:one)
    post.content = ActionText::Content.new("<p>Hello</p>")
    post.save!

    assert_no_enqueued_jobs(only: ActiveStorage::PurgeJob) do
      PurgeUnattachedBlobsJob.perform_now
    end
  end
end
