require "open-uri"
require "resolv"
require "fastimage"

# The Open Graph title, description and image behind a link the author has
# asked to expand into a preview. The URL is author-supplied, so every fetch,
# redirects and the image included, is refused unless the host resolves to a
# public address.
class LinkPreview
  class Error < StandardError; end

  MAX_HTML_BYTES = 500.kilobytes
  MAX_REDIRECTS = 3

  IMAGE_CONTENT_TYPES = {
    jpeg: "image/jpeg",
    png: "image/png",
    gif: "image/gif",
    webp: "image/webp"
  }.freeze

  BLOCKED_RANGES = %w[
    0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16
    172.16.0.0/12 192.168.0.0/16 224.0.0.0/3
    ::1/128 fc00::/7 fe80::/10 ::ffff:0:0/96
  ].map { |range| IPAddr.new(range) }.freeze

  attr_reader :title, :description, :image_width, :image_height

  def initialize(url)
    @url = url
  end

  def fetch
    doc = Nokogiri::HTML(read_page(@url))

    @title = (meta(doc, "og:title") || doc.at("title")&.text&.strip).presence
    @description = meta(doc, "og:description")
    @image_url = meta(doc, "og:image")

    raise Error, "No title found" if @title.nil?

    self
  end

  # nil rather than an error when the image is missing, oversized or not
  # allowed: a preview without a picture is still worth inserting.
  def create_image_blob(allowed_content_types:)
    return if @image_url.blank?

    url = URI.join(@url, @image_url).to_s
    content_type = image_content_type(url)
    return unless content_type && allowed_content_types.include?(content_type)

    io = download(url, limit: UploadLimits::CONTENT_TYPES[content_type])
    ActiveStorage::Blob.create_and_upload!(io: io, filename: image_filename(url, content_type), content_type: content_type)
  rescue Error, URI::Error, OpenURI::HTTPError
    nil
  end

  private

    def meta(doc, property)
      doc.at("meta[property=\"#{property}\"]")&.attr("content")&.strip.presence
    end

    def read_page(url)
      MAX_REDIRECTS.times do
        begin
          return open_public(url).read(MAX_HTML_BYTES)
        rescue OpenURI::HTTPRedirect => redirect
          url = redirect.uri.to_s
        end
      end

      raise Error, "Too many redirects"
    end

    def image_content_type(url)
      ensure_public!(url)

      if size = FastImage.size(url)
        @image_width, @image_height = size
      end

      IMAGE_CONTENT_TYPES[FastImage.type(url)]
    end

    def download(url, limit:)
      too_big = ->(bytes) { raise Error, "Image too large" if bytes && bytes > limit }
      open_public(url, content_length_proc: too_big, progress_proc: too_big)
    end

    def open_public(url, **options)
      ensure_public!(url)
      URI.open(url, redirect: false, open_timeout: 5, read_timeout: 5, **options)
    end

    def ensure_public!(url)
      uri = URI.parse(url)
      raise Error, "Not an HTTPS URL" unless uri.is_a?(URI::HTTPS)

      addresses = Resolv.getaddresses(uri.hostname).map { |address| IPAddr.new(address) }
      if addresses.empty? || addresses.any? { |address| BLOCKED_RANGES.any? { |range| range.include?(address) } }
        raise Error, "Not a public host"
      end
    rescue IPAddr::InvalidAddressError, URI::InvalidURIError
      raise Error, "Invalid URL"
    end

    def image_filename(url, content_type)
      File.basename(URI.parse(url).path.to_s).presence || "preview.#{content_type.split("/").last}"
    end
end
