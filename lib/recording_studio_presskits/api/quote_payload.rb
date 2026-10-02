# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class QuotePayload
      def self.for(recordable)
        { body: recordable.body, name: recordable.name }.tap do |payload|
          assign_present(payload, :role, recordable.role)
          assign_present(payload, :organisation, recordable.organisation)
        end
      end

      def self.assign_present(payload, key, value)
        stripped = value.to_s.strip
        payload[key] = stripped if stripped.present?
      end
      private_class_method :assign_present
    end
  end
end
