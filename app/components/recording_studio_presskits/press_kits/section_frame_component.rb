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
          spacing: images_download_button ? :none : :md,
          level: :h2,
          anchor_link: true,
          trailing: images_count_badge
        )
      end

      def images_download_button
        return @images_download_button if defined?(@images_download_button)

        @images_download_button = build_images_download_button
      end

      def text_section?
        content_recording&.recordable.is_a?(RecordingStudioPresskits::Text)
      end

      def text_heading
        TextSectionHeadingComponent.new(section_recording: @section_recording)
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

      private

      def image_archive_href(content)
        presskits_routes.image_archive_path(content)
      end

      def presskits_routes
        return helpers.recording_studio_presskits if helpers.respond_to?(:recording_studio_presskits)

        helpers
      end

      def images_count_badge
        content = @content_recording
        return unless content&.recordable.is_a?(Images)

        count = DirectImages.list(content).size
        return if count.zero?

        FlatPack::Badge::Component.new(text: count.to_s, size: :sm)
      end

      def build_images_download_button
        content = @content_recording
        return unless content&.recordable.is_a?(Images)
        return if DirectImages.list(content).empty?

        FlatPack::Button::Component.new(
          text: I18n.t("recording_studio_presskits.images.download_all"),
          style: :default,
          icon: "arrow-down-tray",
          href: image_archive_href(content),
          data: { turbo: false }
        )
      end
    end
  end
end
