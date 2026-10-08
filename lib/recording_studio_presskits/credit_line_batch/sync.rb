# frozen_string_literal: true

module RecordingStudioPresskits
  class CreditLineBatch
    class Sync
      def self.call(section_recording:, root_recording:, rows:, actor:)
        new(section_recording:, root_recording:, rows:, actor:).call
      end

      def initialize(section_recording:, root_recording:, rows:, actor:)
        @section_recording = section_recording
        @root_recording = root_recording
        @rows = Array(rows)
        @actor = actor
      end

      def call
        ActiveRecord::Base.transaction do
          kept = @rows.filter_map { |row| apply(row) }
          reorder(kept)
        end
      end

      private

      def apply(row)
        return unless row.respond_to?(:[])
        return remove(row) if destroy?(row)
        return revise(row) if line_id(row)

        add(row)
      end

      def destroy?(row)
        ActiveModel::Type::Boolean.new.cast(row[:_destroy])
      end

      def remove(row)
        line = find_line(row)
        Credits.remove!(line, actor: @actor) if line
        nil
      end

      def revise(row)
        line = find_line(row)
        return if line.blank?

        Credits.revise_role!(line_recording: line, root_recording: @root_recording, role: row[:role])
        line.id
      end

      def add(row)
        credit_id = row[:credit_recording_id].to_s.strip.presence
        return if credit_id.blank?

        Credits.add!(
          credits_section_recording: @section_recording,
          credit_recording: Credits.find_for_root(@root_recording, credit_id),
          role: row[:role],
          actor: @actor
        ).id
      end

      def find_line(row)
        Credits.find_line(@section_recording, line_id(row))
      end

      def line_id(row)
        row[:id].to_s.strip.presence
      end

      def reorder(ids)
        current = Credits.lines_for(@section_recording).map { |line| line.id.to_s }
        wanted = ids.map(&:to_s)
        return if current == wanted || current.sort != wanted.sort

        @section_recording.recording_studio_orderable_reorder!(ordered_recording_ids: ids, actor: @actor)
      end
    end
  end
end
