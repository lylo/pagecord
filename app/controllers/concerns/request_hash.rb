module RequestHash
  extend ActiveSupport::Concern

  included do
    before_action :load_hash_id
  end

  private

    def load_hash_id
      @hash_id = request_hash(:year)
    end

    def request_hash(duration = :day)
      salt = ENV["SALT"] || "1e57a452a094728c291bc42bf2bc7eb8d9fd8844d1369da2bf728588b46c4e75"

      ip = request.remote_ip
      date_component = case duration
      when :year
        Time.zone.now.year
      else
        Time.zone.now.to_date
      end

      string_to_hash = "#{ip}-#{date_component}-#{salt}"
      Digest::SHA256.hexdigest(string_to_hash)
    end
end
