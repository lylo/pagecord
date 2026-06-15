module MediaEmbed
  module Providers
    class << self
      def all
        [
          AppleMusic,
          Spotify,
          Youtube,
          Bandcamp,
          Bluesky,
          Strava,
          Github,
          Image,
          Transistor,
          Checkvist,
          Tidal
        ]
      end
    end
  end
end
