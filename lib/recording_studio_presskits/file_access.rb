# frozen_string_literal: true

module RecordingStudioPresskits
  # Attachable calls this for every file action. Upload and edit stay on the
  # usual role check. Reading or downloading the bytes requires the kit download.
  class FileAccess
    BYTE_ACTIONS = %i[view download].freeze

    def self.call(action:, actor:, recording:, role:)
      if BYTE_ACTIONS.include?(action.to_sym)
        kit = kit_for(recording)
        return false if kit.blank?

        return KitDownload.allowed?(kit, actor: actor)
      end

      return false unless defined?(RecordingStudioAccessible::Authorization)

      RecordingStudioAccessible::Authorization.allowed?(actor: actor, recording: recording, role: role)
    end

    def self.kit_for(recording)
      current = recording
      6.times do
        return current if current&.recordable.is_a?(PressKit)

        current = current&.parent_recording
        return if current.blank?
      end
    end
  end
end
