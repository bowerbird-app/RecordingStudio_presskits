# frozen_string_literal: true

module RecordingStudioPresskits
  class Text
    class EditComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @text = recording.recordable
        @update_path = update_path
      end

      def cancel_path
        helpers.edit_press_kit_path(@recording.parent_recording)
      end

      def self.param_key
        :text
      end

      def self.permitted_attributes
        [:body]
      end
    end
  end
end
