# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class CreditLinePayload
      def self.for(recording)
        return {} if recording.blank?

        credit = Credits.credit_for(recording)
        payload = {}
        assign_present(payload, :role, recording.recordable.role)
        payload[:credit_id] = credit.id if credit
        assign_credit(payload, credit)
        payload
      end

      def self.assign_credit(payload, credit)
        return unless Credits.shown_credit?(credit)

        assign_present(payload, :name, credit.recordable.name)
        assign_present(payload, :url, credit.recordable.url)
      end
      private_class_method :assign_credit

      def self.assign_present(payload, key, value)
        stripped = value.to_s.strip
        payload[key] = stripped if stripped.present?
      end
      private_class_method :assign_present
    end
  end
end
