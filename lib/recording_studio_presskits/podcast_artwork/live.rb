# frozen_string_literal: true

require "net/http"
require "resolv"
require "ipaddr"

module RecordingStudioPresskits
  class PodcastArtwork
    # HTTPS GET that refuses loopback, private, and link-local addresses.
    class Live
      # A short name gets Spotify's tagged page. Some other hosts answer 403,
      # so those requests are tried again with a browser name.
      CLIENT_NAME = "RecordingStudioPresskits"
      BROWSER = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " \
                "(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"

      def self.call(uri)
        new.call(uri)
      end

      def call(uri)
        return unless public_destination?(uri)

        response = fetch(uri)
        [response.code.to_i, response.body.to_s, response.content_type.to_s, response["location"]]
      end

      private

      def fetch(uri)
        response = get(uri, CLIENT_NAME)
        return response unless response.code.to_i == 403

        get(uri, BROWSER)
      end

      def get(uri, agent)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 4
        http.read_timeout = 8
        http.request(Net::HTTP::Get.new(uri, { "User-Agent" => agent }))
      end

      def public_destination?(uri)
        addresses = Resolv.getaddresses(uri.host.to_s)
        return false if addresses.empty?

        addresses.all? { |ip| public_ip?(ip) }
      rescue Resolv::ResolvError, IPAddr::InvalidAddressError, SocketError
        false
      end

      def public_ip?(ip)
        address = IPAddr.new(ip)
        !address.loopback? && !address.private? && !address.link_local?
      end
    end
  end
end
