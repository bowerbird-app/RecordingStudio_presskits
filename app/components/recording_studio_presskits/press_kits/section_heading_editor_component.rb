# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionHeadingEditorComponent < ViewComponent::Base
      def initialize(section:, update_path:)
        super()
        @section = section
        @update_path = update_path
      end

      def section_title
        @section.recordable.title
      end

      def section_title_fallback
        RecordingStudioPresskits.default_section_heading(@section)
      end

      def section_subtitle
        @section.recordable.subtitle
      end

      def update_button
        FlatPack::Button::Component.new(
          text: "Update",
          style: :default,
          type: "submit",
          data: { "flat-pack--unsaved-changes-target": "submit" }
        )
      end
    end
  end
end
