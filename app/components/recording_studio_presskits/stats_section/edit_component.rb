# frozen_string_literal: true

module RecordingStudioPresskits
  class StatsSection
    class EditComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @update_path = update_path
      end

      attr_reader :update_path

      class << self
        def param_key
          :stats_section
        end

        def permitted_attributes
          []
        end

        def below?
          true
        end
      end

      def stats
        StatsSection.active_stats(@recording)
      end

      def section_actions
        ActionsComponent.new(recording: @recording)
      end

      def order_path
        helpers.press_kit_section_stat_order_path(kit_recording, kit_section_recording)
      end

      def edit_path(stat_recording)
        helpers.edit_press_kit_section_stat_path(kit_recording, kit_section_recording, stat_recording)
      end

      def remove_path(stat_recording)
        helpers.press_kit_section_stat_path(kit_recording, kit_section_recording, stat_recording)
      end

      def stat_label(stat_recording)
        stat_recording.recordable.label.to_s.strip.presence || "Stat"
      end

      def stat_summary(stat_recording)
        stat_recording.recordable.formatted_value.presence
      end

      private

      def kit_section_recording
        @recording.parent_recording
      end

      def kit_recording
        kit_section_recording.parent_recording
      end
    end
  end
end
