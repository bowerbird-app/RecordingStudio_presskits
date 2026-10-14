# frozen_string_literal: true

module RecordingStudioPresskits
  class ListItem
    class EditComponent < ViewComponent::Base
      def initialize(item:, section_recording:, item_recording: nil)
        super()
        @item = item
        @section_recording = section_recording
        @item_recording = item_recording
      end

      attr_reader :item

      def heading
        item.key.to_s.strip.presence || "Item"
      end

      def form_path
        if @item_recording&.persisted?
          helpers.press_kit_section_list_item_path(kit_recording, @section_recording, @item_recording)
        else
          helpers.press_kit_section_list_items_path(kit_recording, @section_recording)
        end
      end

      def form_method
        @item_recording&.persisted? ? :patch : :post
      end

      def form_data
        @item_recording&.persisted? ? helpers.presskits_editor_save_data : {}
      end

      def cancel_path
        helpers.edit_press_kit_section_path(kit_recording, @section_recording)
      end

      def icon_options
        [["None", ""]] + Icons.choices
      end

      private

      def kit_recording
        @section_recording.parent_recording
      end
    end
  end
end
