# frozen_string_literal: true

module RecordingStudioPresskits
  # record! ignores parent_recording once a recording exists, so the move uses
  # Recording#update!, which still checks the declared parent.
  class LegacySectionTree
    SHIPPED = %w[
      RecordingStudioPresskits::Text
      RecordingStudioPresskits::Images
      RecordingStudioPresskits::QuoteSection
    ].freeze

    class << self
      def migrate!
        groups = legacy_recordings.group_by(&:parent_recording_id)
        RecordingStudio::Recording.transaction do
          groups.each_value { |recordings| recordings.each { |recording| wrap(recording) } }
        end
      end

      private

      def legacy_recordings
        RecordingStudio::Recording.unscoped
                                  .where(recordable_type: legacy_type_names)
                                  .includes(:parent_recording, :recordable)
                                  .order(:recording_studio_orderable_position, :created_at, :id)
                                  .select { |recording| press_kit_parent?(recording) }
      end

      def legacy_type_names
        (SHIPPED + RecordingStudioPresskits.section_types - [KitSection.name]).uniq
      end

      def press_kit_parent?(recording)
        recording.parent_recording&.recordable_type == PressKit.name && recording.recordable.present?
      end

      def wrap(content_recording)
        press_kit = content_recording.parent_recording
        title, subtitle = headings_for(content_recording.recordable)
        section = record_section(press_kit, title, subtitle)
        keep_place!(section, content_recording)
        content_recording.update!(parent_recording: section)
        move_trash_state!(section, content_recording)
        section
      end

      def record_section(press_kit, title, subtitle)
        press_kit.record(KitSection, parent_recording: press_kit, actor: actor_for(press_kit)) do |section|
          section.title = title
          section.subtitle = subtitle
        end
      end

      def actor_for(press_kit)
        press_kit.events.order(:created_at).find { |event| event.actor.present? }&.actor
      end

      def headings_for(recordable)
        return ["Quotes", nil] if recordable.is_a?(QuoteSection)

        [column_value(recordable, "title"), column_value(recordable, "subtitle")]
      end

      def column_value(recordable, name)
        return unless recordable.class.column_names.include?(name)

        recordable.public_send(name)
      end

      def keep_place!(section_recording, content_recording)
        section_recording.update!(
          recording_studio_orderable_position: content_recording.recording_studio_orderable_position
        )
      end

      def move_trash_state!(section_recording, content_recording)
        return if content_recording.trashed_at.blank?

        was_root = content_recording.trash_root
        section_recording.update!(trashed_at: content_recording.trashed_at, trash_root: was_root)
        content_recording.update!(trash_root: false) if was_root
      end
    end
  end
end
