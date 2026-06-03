require "test_helper"

class StandardSite::PublicationTest < ActiveSupport::TestCase
  test "builds a publication record from the blog" do
    blog = blogs(:joel)
    publication = blog.build_standard_site_publication

    record = publication.record

    assert_equal "site.standard.publication", record["$type"]
    assert_equal "http://joel.example.com", record["url"]
    assert_equal blog.display_name, record["name"]
    assert_equal true, record["preferences"]["showInDiscover"]
  end

  test "sync stores returned at uri and cid" do
    blog = blogs(:joel)
    account = blog.create_standard_site_account!(
      handle: "joel.bsky.social",
      did: "did:plc:joel123",
      pds_url: "https://bsky.social",
      connected_at: Time.current
    )
    account.access_jwt = "access-token"
    account.refresh_jwt = "refresh-token"
    account.save!

    publication = blog.create_standard_site_publication!

    StandardSite::Client.any_instance.expects(:put_record).with(
      collection: "site.standard.publication",
      rkey: "self",
      record: publication.record
    ).returns({
      "uri" => "at://did:plc:joel123/site.standard.publication/self",
      "cid" => "bafyreipublication"
    })

    publication.sync!

    assert publication.synced?
    assert_equal "at://did:plc:joel123/site.standard.publication/self", publication.at_uri
    assert_equal "bafyreipublication", publication.cid
  end
end
