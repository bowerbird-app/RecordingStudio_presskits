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
          spacing: heading_action? ? :none : :md,
          level: :h2,
          anchor_link: true,
          trailing: section_count_badge
        )
      end

      def images_download_button
        return @images_download_button if defined?(@images_download_button)

        @images_download_button = build_images_download_button
      end

      def credits_copy_button
        return @credits_copy_button if defined?(@credits_copy_button)

        @credits_copy_button = build_credits_copy_button
      end

      def text_section?
        content_recording&.recordable.is_a?(RecordingStudioPresskits::Text)
      end

      def text_heading
        TextSectionHeadingComponent.new(
          section_recording: @section_recording,
          clipboard_text: text_clipboard_text
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

      private

      def text_clipboard_text
        return unless text_section?

        RecordingStudioPresskits::Text.clipboard_text(content_recording.recordable.body)
      end

      def image_archive_href(content)
        presskits_routes.image_archive_path(content)
      end

      def presskits_routes
        return helpers.recording_studio_presskits if helpers.respond_to?(:recording_studio_presskits)

        helpers
      end

      def section_count_badge
        content = @content_recording
        recordable = content&.recordable
        count = if recordable.is_a?(Images)
                  DirectImages.list(content).size
                elsif recordable.is_a?(VideoSection)
                  VideoSection.active_videos(content).size
                end
        return if count.nil? || count.zero?

        FlatPack::Badge::Component.new(text: count.to_s, size: :sm)
      end

      def heading_action?
        images_download_button.present? || credits_copy_button.present?
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

      def build_credits_copy_button
        view = content_view
        return unless view.respond_to?(:copy_button)

        view.copy_button
      end
    end
  end
end
