# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class LocationPayload
      KEYS = LocationContent::ATTRIBUTES

      def self.for(recordable)
        KEYS.index_with { |name| value_for(recordable, name) }
      end

      def self.value_for(recordable, name)
        value = recordable.public_send(name)
        return if value.nil?
        return value.to_f if %i[latitude longitude].include?(name)

        stripped = value.to_s.strip
        stripped.presence
      end
      private_class_method :value_for
    end
  end
end
