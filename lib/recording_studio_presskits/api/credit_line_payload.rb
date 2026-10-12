# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class CreditLinePayload
      def self.for(recording)
        return {} if recording.blank?

        recordable = recording.recordable
        payload = {}
        assign_present(payload, :name, recordable.name)
        assign_present(payload, :role, recordable.role)
        assign_present(payload, :url, recordable.url)
        payload
      end

      def self.assign_present(payload, key, value)
        stripped = value.to_s.strip
        payload[key] = stripped if stripped.present?
      end
      private_class_method :assign_present
    end
  end
end
