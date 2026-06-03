require "httparty"

class StandardSite::Client
  class Error < StandardError; end

  def self.connect(handle:, app_password:, pds_url: "https://bsky.social")
    response = HTTParty.post(
      "#{pds_url.delete_suffix("/")}/xrpc/com.atproto.server.createSession",
      headers: { "Content-Type" => "application/json" },
      body: {
        identifier: handle.to_s.delete_prefix("@"),
        password: app_password
      }.to_json
    )

    raise Error, error_message(response) unless response.success?

    response.parsed_response
  end

  def self.error_message(response)
    body = response.parsed_response
    body.is_a?(Hash) ? body["message"].presence || body["error"].presence || response.message : response.message
  end

  def initialize(account)
    @account = account
  end

  def put_record(collection:, rkey:, record:)
    response = put_record_request(collection: collection, rkey: rkey, record: record)
    response = refresh_and_retry(collection: collection, rkey: rkey, record: record) if response.code == 401

    raise Error, self.class.error_message(response) unless response.success?

    response.parsed_response
  end

  private

    def put_record_request(collection:, rkey:, record:)
      HTTParty.post(
        "#{@account.pds_url}/xrpc/com.atproto.repo.putRecord",
        headers: {
          "Authorization" => "Bearer #{@account.access_jwt}",
          "Content-Type" => "application/json"
        },
        body: {
          repo: @account.did,
          collection: collection,
          rkey: rkey,
          record: record,
          validate: true
        }.to_json
      )
    end

    def refresh_and_retry(collection:, rkey:, record:)
      refresh_session
      put_record_request(collection: collection, rkey: rkey, record: record)
    end

    def refresh_session
      response = HTTParty.post(
        "#{@account.pds_url}/xrpc/com.atproto.server.refreshSession",
        headers: { "Authorization" => "Bearer #{@account.refresh_jwt}" }
      )

      raise Error, self.class.error_message(response) unless response.success?

      session = response.parsed_response
      @account.update!(
        access_jwt: session.fetch("accessJwt"),
        refresh_jwt: session.fetch("refreshJwt"),
        handle: session.fetch("handle", @account.handle),
        did: session.fetch("did", @account.did)
      )
    end
end
