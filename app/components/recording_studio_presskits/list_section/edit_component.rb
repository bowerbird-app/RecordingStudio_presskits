# frozen_string_literal: true

module RecordingStudioPresskits
  class ListSection
    class EditComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @update_path = update_path
      end

      attr_reader :update_path

      class << self
        def param_key
          :list_section
        end

        def permitted_attributes
          []
        end

        def below?
          true
        end
      end

      def batch
        supplied = helpers.controller.instance_variable_get(:@list_item_batch)
        supplied || ListItemBatch.for_section(@recording)
      end

      def blank_line
        ListItemBatch::LineDraft.new
      end

      def lines_path
        helpers.press_kit_section_list_lines_path(kit_recording, kit_section_recording)
      end

      def order_path
        helpers.press_kit_section_list_item_order_path(kit_recording, kit_section_recording)
      end

      def icon_options
        [["None", ""]] + Icons.choices
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
