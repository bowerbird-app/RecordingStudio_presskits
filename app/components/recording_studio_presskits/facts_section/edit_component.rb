# frozen_string_literal: true

module RecordingStudioPresskits
  class FactsSection
    class EditComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @update_path = update_path
      end

      class << self
        def param_key
          :facts_section
        end

        def permitted_attributes
          %i[display_style columns]
        end

        def below?
          true
        end
      end

      def facts
        FactsSection.active_facts(@recording)
      end

      def section
        @recording.recordable
      end

      def section_actions
        ActionsComponent.new(recording: @recording)
      end

      def order_path
        helpers.press_kit_section_fact_order_path(kit_recording, kit_section_recording)
      end

      def edit_path(fact_recording)
        helpers.edit_press_kit_section_fact_path(kit_recording, kit_section_recording, fact_recording)
      end

      def remove_path(fact_recording)
        helpers.press_kit_section_fact_path(kit_recording, kit_section_recording, fact_recording)
      end

      def fact_label(fact_recording)
        fact_recording.recordable.label.to_s.strip.presence || "Fact"
      end

      def fact_summary(fact_recording)
        fact_recording.recordable.formatted_value.presence
      end

      def display_style_options
        [
          ["List", "list"],
          ["Cards", "cards"],
          ["Table", "table"]
        ]
      end

      def column_options
        FactsSection::COLUMN_COUNTS.map { |count| [count.to_s, count] }
      end

      def update_path
        @update_path
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
