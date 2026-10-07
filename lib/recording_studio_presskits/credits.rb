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

      def add!(credits_section_recording:, credit_recording:, role: nil, actor: nil)
        assert_usable!(credits_section_recording, credit_recording)
        record_line(credits_section_recording, credit_recording, role, actor)
      end

      def revise_role!(line_recording:, root_recording:, role:)
        root_recording.revise(line_recording) { |line| line.role = role }
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
        lines_for(section_recording).select { |line| shown_credit?(credit_for(line)) }
      end

      def credit_for(line_recording)
        id = line_recording&.recordable&.try(:credit_recording_id)
        return if id.blank?

        RecordingStudio::Recording.includes(:recordable).find_by(id: id)
      end

      def shown_credit?(credit_recording)
        credit_recording.present? && credit_recording.trashed_at.nil? && credit_recording.recordable.is_a?(Credit)
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

      def assert_usable!(section_recording, credit_recording)
        return if usable_credit?(section_recording, credit_recording)

        raise ArgumentError, "That credit is not in this workspace"
      end

      def usable_credit?(section_recording, credit_recording)
        shown_credit?(credit_recording) &&
          credit_recording.root_recording_id == section_recording.root_recording_id &&
          credit_recording.parent_recording_id == section_recording.root_recording_id
      end

      def record_line(section_recording, credit_recording, role, actor)
        section_recording.record(CreditLine, parent_recording: section_recording, actor: actor) do |line|
          line.credit_recording_id = credit_recording.id
          line.role = chosen_role(role, credit_recording)
        end
      end

      def chosen_role(role, credit_recording)
        role.to_s.strip.presence || credit_recording.recordable.usual_role
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
