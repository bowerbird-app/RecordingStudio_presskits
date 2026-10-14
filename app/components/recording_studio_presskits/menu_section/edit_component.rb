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
        [:layout, :show_counts, :show_icons, { excluded_section_ids: [] }]
      end

      def layout_options
        [%w[Grid grid], %w[List list]]
      end

      def exclusion_candidates
        siblings.reject { |section| section.id == kit_section&.id || menu_content?(section) }
      end

      def excluded?(section)
        Array(@menu.excluded_section_ids).map(&:to_s).include?(section.id.to_s)
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
