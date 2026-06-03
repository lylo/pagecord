require "test_helper"

class StandardSite::DocumentTest < ActiveSupport::TestCase
  test "builds a document record from the post" do
    blog = blogs(:joel)
    post = posts(:one)
    blog.create_standard_site_publication!(
      at_uri: "at://did:plc:joel123/site.standard.publication/self",
      sync_status: :synced
    )
    document = post.build_standard_site_document

    record = document.record

    assert_equal "site.standard.document", record["$type"]
    assert_equal "at://did:plc:joel123/site.standard.publication/self", record["site"]
    assert_equal "/the-art-of-street-photography", record["path"]
    assert_equal post.display_title, record["title"]
    assert_equal [ "photography" ], record["tags"]
    assert_equal post.published_at.utc.iso8601(3), record["publishedAt"]
  end

  test "sync disables records for drafts" do
    blog = blogs(:joel)
    post = posts(:joel_draft)
    document = post.create_standard_site_document!(rkey: post.token)
    blog.create_standard_site_publication!(
      at_uri: "at://did:plc:joel123/site.standard.publication/self",
      sync_status: :synced
    )

    document.sync!

    assert document.disabled?
  end
end
