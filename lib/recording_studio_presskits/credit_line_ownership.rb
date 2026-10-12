# frozen_string_literal: true

module RecordingStudioPresskits
  # Copies workspace credit name and URL onto each credit line.
  # Lines whose credit is trashed are hidden so the public page stays the same.
  # A later release drops the shared credit rows.
  class CreditLineOwnership
    HIDE_TABLE = "recording_studio_credit_line_library_hides"

    def self.migrate!
      new.migrate!
    end

    def self.revert!
      new.revert!
    end

    def migrate!
      CreditLine.reset_column_information
      each_line { |line, recording| copy_line(line, recording) }
    end

    def revert!
      restore_hidden_lines
      delete_lines_without_credit
    end

    private

    def each_line
      CreditLine.find_each do |line|
        recording = line_recording(line)
        next if recording.blank?

        yield line, recording
      end
    end

    def copy_line(line, recording)
      credit_recording = credit_recording_for(line)
      assign_owned_fields(line, credit_recording) if line.name.blank?
      hide_line(recording) if hide_line?(credit_recording, recording)
    end

    def assign_owned_fields(line, credit_recording)
      credit = credit_recordable(credit_recording)
      CreditLine.where(id: line.id).update_all(name: copied_name(line, credit), url: copied_url(credit))
    end

    def copied_name(line, credit)
      credit&.name.to_s.strip.presence || line.role.to_s.strip.presence || "Credit"
    end

    def copied_url(credit)
      credit&.url.to_s.strip.presence
    end

    def hide_line?(credit_recording, recording)
      credit_recording&.trashed_at.present? && recording.trashed_at.blank? && !hidden?(recording)
    end

    def hide_line(recording)
      recording.update_columns(trashed_at: Time.current, trash_root: true)
      connection.execute(<<~SQL.squish)
        INSERT INTO #{HIDE_TABLE} (id, line_recording_id, created_at)
        VALUES (#{connection.quote(SecureRandom.uuid)}, #{connection.quote(recording.id)}, #{connection.quote(Time.current)})
        ON CONFLICT (line_recording_id) DO NOTHING
      SQL
    end

    def restore_hidden_lines
      return unless connection.data_source_exists?(HIDE_TABLE)

      hidden_ids.each do |id|
        recording = RecordingStudio::Recording.find_by(id: id)
        next if recording.blank?

        recording.update_columns(trashed_at: nil, trash_root: false)
      end
    end

    def delete_lines_without_credit
      CreditLine.reset_column_information
      CreditLine.where(credit_recording_id: nil).find_each do |line|
        recording = line_recording(line)
        recording&.destroy!
        CreditLine.where(id: line.id).delete_all
      end
    end

    def hidden_ids
      connection.select_values("SELECT line_recording_id FROM #{HIDE_TABLE}")
    end

    def hidden?(recording)
      connection.select_value(<<~SQL.squish).present?
        SELECT 1 FROM #{HIDE_TABLE} WHERE line_recording_id = #{connection.quote(recording.id)} LIMIT 1
      SQL
    end

    def credit_recording_for(line)
      return if line.credit_recording_id.blank?

      RecordingStudio::Recording.includes(:recordable).find_by(id: line.credit_recording_id)
    end

    def credit_recordable(recording)
      recordable = recording&.recordable
      recordable if recordable.is_a?(Credit)
    end

    def line_recording(line)
      RecordingStudio::Recording.find_by(recordable_type: CreditLine.name, recordable_id: line.id)
    end

    def connection
      ActiveRecord::Base.connection
    end
  end
end
