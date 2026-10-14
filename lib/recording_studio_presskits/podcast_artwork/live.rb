# frozen_string_literal: true

require "net/http"
require "resolv"
require "ipaddr"

module RecordingStudioPresskits
  class PodcastArtwork
    # HTTPS GET that refuses loopback, private, and link-local addresses.
    class Live
      def self.call(uri)
        new.call(uri)
      end

      def call(uri)
        return unless public_destination?(uri)

        response = get(uri)
        [response.code.to_i, response.body.to_s, response.content_type.to_s, response["location"]]
      end

      private

      def get(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 2
        http.read_timeout = 3
        http.request(Net::HTTP::Get.new(uri, { "User-Agent" => "RecordingStudioPresskits" }))
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
