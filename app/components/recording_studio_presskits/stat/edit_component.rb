# frozen_string_literal: true

module RecordingStudioPresskits
  class Stat
    class EditComponent < ViewComponent::Base
      def initialize(stat:, section_recording:, stat_recording: nil)
        super()
        @stat = stat
        @section_recording = section_recording
        @stat_recording = stat_recording
      end

      attr_reader :stat

      def heading
        stat.label.to_s.strip.presence || "Stat"
      end

      def form_path
        if @stat_recording&.persisted?
          helpers.press_kit_section_stat_path(kit_recording, @section_recording, @stat_recording)
        else
          helpers.press_kit_section_stats_path(kit_recording, @section_recording)
        end
      end

      def form_method
        @stat_recording&.persisted? ? :patch : :post
      end

      def form_data
        @stat_recording&.persisted? ? helpers.presskits_editor_save_data : {}
      end

      def cancel_path
        helpers.edit_press_kit_section_path(kit_recording, @section_recording)
      end

      private

      def kit_recording
        @section_recording.parent_recording
      end
    end
  end
end
