# frozen_string_literal: true

module RecordingStudioPresskits
  class MenuSection
    class EditComponent < ViewComponent::Base
      def initialize(recording:, update_path:)
        super()
        @recording = recording
        @menu = recording.recordable
        @update_path = update_path
      end

      def self.param_key
        :menu_section
      end

      def self.permitted_attributes
        %i[layout show_counts show_icons]
      end

      def self.permit(raw)
        permitted = raw.permit(*permitted_attributes)
        permitted.merge(items: permitted_items(raw[:items]))
      end

      def self.permitted_items(items)
        raw = items.respond_to?(:to_unsafe_h) ? items.to_unsafe_h : items
        return {} unless raw.is_a?(Hash)

        raw.each_with_object({}) do |(section_id, attrs), kept|
          next if section_id.blank?
          next unless attrs.is_a?(Hash)

          kept[section_id.to_s] = ActionController::Parameters.new(attrs).permit(:label, :shown, :hidden).to_h
        end
      end

      def layout_options
        [%w[Grid grid], %w[List list]]
      end

      def section_rows
        siblings.reject { |section| section.id == kit_section&.id || menu_content?(section) }
      end

      def short_label(section)
        @menu.item_for(section.id).label
      end

      def shown?(section)
        @menu.item_for(section.id).shown?
      end

      def heading_for(section)
        RecordingStudioPresskits.section_heading(section)
      end

      private

      def siblings
        kit = kit_section&.parent_recording
        return [] if kit.blank?

        KitQuery.sections_for(kit).to_a
      end

      def kit_section
        @recording.parent_recording
      end

      def menu_content?(section)
        KitQuery.section_content(section)&.recordable.is_a?(MenuSection)
      end
    end
  end
end
