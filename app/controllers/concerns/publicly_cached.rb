module PubliclyCached
  extend ActiveSupport::Concern

  private

    # These pages print a price that Cloudflare geolocates per visitor, so its
    # cache key has to include the country. The session is skipped because a
    # cookie makes Cloudflare bypass the cache entirely.
    def cache_publicly(maxage:, stale: 10.minutes)
      request.session_options[:skip] = true
      response.headers["Vary"] = "CF-IPCountry"

      expires_in 0, public: true, "s-maxage": maxage.to_i, "stale-while-revalidate": stale.to_i
    end
end
