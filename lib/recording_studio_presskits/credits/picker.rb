# frozen_string_literal: true

module RecordingStudioPresskits
  module Credits
    module Picker
      class << self
        def search(root_recording, query)
          { items: recordings(root_recording, query).map { |recording| item(recording) } }
        end

        def created(recording)
          { ok: true, item: item(recording) }
        end

        def rejected
          { ok: false, errors: ["Give them a name."] }
        end

        def item(recording)
          credit = recording.recordable
          { id: recording.id, title: credit.name, description: credit.usual_role }
        end

        private

        def recordings(root_recording, query)
          term = query.to_s.strip
          return RecordingStudio::Recording.none if term.empty?

          Credits.active_for_root(root_recording).where(recordable_id: matching_credit_ids(term)).limit(20)
        end

        def matching_credit_ids(term)
          escaped = "%#{Credit.sanitize_sql_like(term)}%"
          Credit.where("name ILIKE :term OR usual_role ILIKE :term", term: escaped).select(:id)
        end
      end
    end
  end
end
