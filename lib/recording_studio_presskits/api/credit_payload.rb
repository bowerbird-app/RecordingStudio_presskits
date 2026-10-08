# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class CreditPayload
      def self.for(recordable)
        { name: recordable.name.to_s }.tap do |payload|
          assign_present(payload, :url, recordable.url)
          assign_present(payload, :usual_role, recordable.usual_role)
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
