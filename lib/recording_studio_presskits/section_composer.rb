# frozen_string_literal: true

module RecordingStudioPresskits
  class SectionComposer
    class << self
      def create!(press_kit_recording:, content_type:, actor: nil, title: nil, subtitle: nil)
        type_name = content_type_name(content_type)
        assert_content_type!(type_name)

        RecordingStudio::Recording.transaction do
          section = record_section(press_kit_recording, actor, title, subtitle)
          record_content(section, type_name, actor, title)
          section
        end
      end

      def update!(section_recording:, root_recording:, headings: nil, content_attributes: nil)
        assert_section!(section_recording)

        RecordingStudio::Recording.transaction do
          revise_headings(section_recording, root_recording, headings)
          revise_content(section_recording, root_recording, content_attributes)
        end

        section_recording
      end

      private

      def content_type_name(content_type)
        RecordingStudio.recordable_type_name(content_type).to_s
      end

      def assert_content_type!(type_name)
        return if RecordingStudioPresskits.section_types.include?(type_name) && declared_under_section?(type_name)

        raise ArgumentError, "#{type_name} is not a press kit section content type"
      end

      def declared_under_section?(type_name)
        RecordingStudio.declared_allowed_parent_types_for(type_name).include?(KitSection.name)
      end

      def assert_section!(section_recording)
        return if section_recording&.recordable.is_a?(KitSection)

        raise ArgumentError, "expected a kit section recording"
      end

      def record_section(press_kit_recording, actor, title, subtitle)
        press_kit_recording.record(KitSection, parent_recording: press_kit_recording, actor: actor) do |section|
          section.title = title
          section.subtitle = subtitle
        end
      end

      def record_content(section_recording, type_name, actor, title)
        section_recording.record(
          type_name.constantize,
          parent_recording: section_recording,
          actor: actor
        ) do |recordable|
          RecordingStudioPresskits.prepare_section_content(type_name, recordable, title: title)
        end
      end

      def revise_headings(section_recording, root_recording, headings)
        return if headings.nil?

        root_recording.revise(section_recording) do |section|
          section.title = headings[:title]
          section.subtitle = headings[:subtitle]
        end
      end

      def revise_content(section_recording, root_recording, content_attributes)
        return if content_attributes.blank?

        content = KitQuery.section_content(section_recording)
        return if content.blank?

        root_recording.revise(content) do |recordable|
          recordable.assign_attributes(content_attributes)
        end
      end
    end
  end
end
