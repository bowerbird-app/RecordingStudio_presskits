# frozen_string_literal: true

module RecordingStudioPresskits
  module Cover
    class Hex
      PATTERN = /\A#?(?:[0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})\z/

      def self.normalize(value)
        raw = value.to_s.strip
        return if raw.blank?
        return unless raw.match?(PATTERN)

        digits = raw.delete_prefix("#")
        digits = digits.chars.map { |digit| digit * 2 }.join if digits.length == 3
        "##{digits.upcase}"
      end

      def self.valid?(value)
        normalize(value).present?
      end

      def self.rgb(value)
        hex = normalize(value)
        return unless hex

        [hex[1, 2].to_i(16), hex[3, 2].to_i(16), hex[5, 2].to_i(16)]
      end
    end
  end
end
