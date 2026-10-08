# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionFrameComponent < ViewComponent::Base
      def initialize(section_recording:)
        super()
        @section_recording = section_recording
        @content_recording = KitQuery.section_content(section_recording)
      end

      def title
        RecordingStudioPresskits.section_heading(@section_recording)
      end

      def subtitle
        @section_recording.recordable.subtitle.to_s.strip.presence
      end

      def saved_title
        @section_recording.recordable.title.to_s.strip.presence
      end

      def content_component
        return if @content_recording.blank?

        RecordingStudioPresskits.section_component_for(@content_recording)
      end

      def render?
        saved_title.present? || subtitle.present? || content_visible?
      end

      def content_visible?
        component = content_component
        return false if component.blank?

        component.new(recording: @content_recording).render?
      end
    end
  end
end
