# frozen_string_literal: true

module RecordingStudioPresskits
  module Credits
    class << self
      def active_for_root(root_recording)
        return RecordingStudio::Recording.none if root_recording.blank?

        live_credits.where(root_recording: root_recording, parent_recording: root_recording)
                    .includes(:recordable)
                    .order(:created_at, :id)
      end

      def find_for_root(root_recording, id)
        return if id.blank?

        active_for_root(root_recording).find_by(id: id)
      end

      def create!(root_recording:, name:, url: nil, usual_role: nil, actor: nil)
        root_recording.record(Credit, parent_recording: root_recording, actor: actor) do |credit|
          assign_credit(credit, name, url, usual_role)
        end
      end

      def revise!(credit_recording:, root_recording:, name:, url:, usual_role:)
        root_recording.revise(credit_recording) do |credit|
          assign_credit(credit, name, url, usual_role)
        end
      end

      def trash!(credit_recording, actor:)
        credit_recording.recording_studio_trashable_trash!(actor: actor)
      end

      def restore!(credit_recording, actor:)
        credit_recording.recording_studio_trashable_restore!(actor: actor)
      end

      def add!(credits_section_recording:, name:, url: nil, role: nil, actor: nil)
        credits_section_recording.record(CreditLine, parent_recording: credits_section_recording, actor: actor) do |line|
          assign_line(line, name, url, role)
        end
      end

      def revise_line!(line_recording:, root_recording:, name:, url:, role:)
        root_recording.revise(line_recording) do |line|
          assign_line(line, name, url, role)
        end
      end

      def remove!(line_recording, actor:)
        line_recording.recording_studio_trashable_trash!(actor: actor)
      end

      def lines_for(section_recording)
        return [] if section_recording.blank?

        section_recording.recording_studio_orderable_children.reject { |child| hidden_line?(child) }
      end

      def find_line(section_recording, id)
        return if section_recording.blank? || id.blank?

        section_recording.child_recordings.where(line_scope).find_by(id: id)
      end

      def visible_lines(section_recording)
        lines_for(section_recording).select { |line| line.recordable.name.to_s.strip.present? }
      end

      private

      def live_credits
        RecordingStudio::Recording.recording_studio_trashable_active.where(recordable_type: Credit.name)
      end

      def assign_credit(credit, name, url, usual_role)
        credit.name = name
        credit.url = url
        credit.usual_role = usual_role
      end

      def assign_line(line, name, url, role)
        line.name = name
        line.url = url
        line.role = role
      end

      def hidden_line?(child)
        child.trashed_at.present? || !child.recordable.is_a?(CreditLine)
      end

      def line_scope
        { trashed_at: nil, recordable_type: CreditLine.name }
      end
    end
  end
end
