# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class PublicShowComponent < ViewComponent::Base
      def initialize(press_kit_recording:, section_recordings: nil, preview: false)
        super()
        @press_kit_recording = press_kit_recording
        @section_recordings = section_recordings
        @preview = preview
      end

      def kit_title
        recordable = @press_kit_recording&.recordable
        recordable&.try(:title).presence || @press_kit_recording&.try(:name).presence || "Press kit"
      end

      def kit_description
        @press_kit_recording&.recordable&.try(:description).to_s.strip.presence
      end

      def page_title_options
        options = { title: kit_title, variant: :h1 }
        options[:subtitle] = kit_description if kit_description.present?
        options
      end

      def section_recordings
        @section_recordings || KitQuery.sections_for(@press_kit_recording)
      end

      def visible_section_recordings
        section_recordings.select { |recording| section_visible?(recording) }
      end

      def preview?
        @preview
      end

      def live?
        @press_kit_recording.respond_to?(:currently_published?) && @press_kit_recording.currently_published?
      end

      def section_visible?(recording)
        SectionFrameComponent.new(section_recording: recording).content_visible?
      end
    end
  end
end
