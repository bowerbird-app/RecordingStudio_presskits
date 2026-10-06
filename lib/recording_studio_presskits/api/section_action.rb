# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module SectionAction
      def self.authorize!(context)
        context.access_grant.authorize!(recording: context.recording, role: :edit)
      end

      def self.require_recording!(recording, kind, message)
        return if recording&.recordable.is_a?(kind)

        reject!(message)
      end

      def self.reject!(message)
        if defined?(::RecordingStudioApi::InvalidActionInputError)
          raise ::RecordingStudioApi::InvalidActionInputError.new(message, details: [message])
        end

        raise ArgumentError, message
      end
    end
  end
end
