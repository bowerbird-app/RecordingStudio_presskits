# frozen_string_literal: true

module RecordingStudioPresskits
  class KitLocation
    TYPE = "RecordingStudio::Location::Location"

    class << self
      def recording_for(parent_recording)
        return unless parent_recording

        RecordingStudio::Recording.recording_studio_trashable_active.find_by(
          parent_recording: parent_recording,
          recordable_type: TYPE
        )
      end

      def recordable_for(parent_recording)
        recording_for(parent_recording)&.recordable
      end

      def save!(parent_recording:, attributes:, actor:, reviser:)
        current = recording_for(parent_recording)
        if blank?(attributes)
          current&.recording_studio_trashable_trash!(actor: actor)
          return
        end

        persist!(parent_recording, current, attributes, actor, reviser)
      end

      def blank?(attributes)
        attributes.values.all?(&:blank?)
      end

      private

      def persist!(parent_recording, current, attributes, actor, reviser)
        if current
          reviser.revise(current) { |location| location.assign_attributes(attributes) }
        else
          parent_recording.record(
            RecordingStudio::Location::Location,
            actor: actor,
            parent_recording: parent_recording
          ) { |location| location.assign_attributes(attributes) }
        end
      end
    end
  end
end
