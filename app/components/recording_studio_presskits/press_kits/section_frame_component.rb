# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionFrameComponent < ViewComponent::Base
      def initialize(section_recording:)
        super()
        @section_recording = section_recording
        @content_recording = KitQuery.section_content(section_recording)
      end

      attr_reader :content_recording

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

      def heading_component
        SectionHeadingComponent.new(
          title: title,
          subtitle: subtitle,
          size: :lg,
          spacing: :md,
          level: :h2,
          anchor_link: true
        )
      end

      def content_view
        component = content_component
        return if component.blank?

        component.new(recording: @content_recording)
      end

      def render?
        content_visible?
      end

      def content_visible?
        view = content_view
        return false if view.blank?
        return true unless view.respond_to?(:render?)

        view.render?
      end
    end
  end
end
