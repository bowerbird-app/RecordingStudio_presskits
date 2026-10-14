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

      def items
        ListSection.active_items(@recording)
      end

      def section_actions
        ActionsComponent.new(recording: @recording)
      end

      def order_path
        helpers.press_kit_section_list_item_order_path(kit_recording, kit_section_recording)
      end

      def edit_path(item_recording)
        helpers.edit_press_kit_section_list_item_path(kit_recording, kit_section_recording, item_recording)
      end

      def remove_path(item_recording)
        helpers.press_kit_section_list_item_path(kit_recording, kit_section_recording, item_recording)
      end

      def item_key(item_recording)
        item_recording.recordable.key.to_s.strip.presence || "Item"
      end

      def item_value(item_recording)
        item_recording.recordable.value.to_s.strip.presence
      end

      def icon_component(recordable)
        return if recordable.icon.blank?

        FlatPack::Shared::IconComponent.new(name: recordable.icon, size: :sm)
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
