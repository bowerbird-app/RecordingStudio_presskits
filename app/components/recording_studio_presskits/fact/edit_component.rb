# frozen_string_literal: true

module RecordingStudioPresskits
  class Fact
    class EditComponent < ViewComponent::Base
      def initialize(fact:, section_recording:, fact_recording: nil)
        super()
        @fact = fact
        @section_recording = section_recording
        @fact_recording = fact_recording
      end

      attr_reader :fact

      def heading
        fact.label.to_s.strip.presence || "Fact"
      end

      def form_path
        if @fact_recording&.persisted?
          helpers.press_kit_section_fact_path(kit_recording, @section_recording, @fact_recording)
        else
          helpers.press_kit_section_facts_path(kit_recording, @section_recording)
        end
      end

      def form_method
        @fact_recording&.persisted? ? :patch : :post
      end

      def form_data
        @fact_recording&.persisted? ? helpers.presskits_editor_save_data : {}
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
