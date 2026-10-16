# frozen_string_literal: true

module RecordingStudioPresskits
  # Filters a root's kits for the index. Published is live now. Draft is
  # everything else except a kit scheduled for later. Search matches the title.
  class KitIndex
    STATUSES = %w[all draft published].freeze

    def self.records(recordings, status:, query:)
      new(recordings, status: status, query: query).records
    end

    def self.status_from(value)
      name = value.to_s
      STATUSES.include?(name) ? name : "all"
    end

    def initialize(recordings, status:, query:)
      @recordings = Array(recordings)
      @status = self.class.status_from(status)
      @query = query.to_s.strip
    end

    def records
      filter_query(filter_status(@recordings))
    end

    private

    def filter_status(list)
      case @status
      when "published"
        list.select { |recording| published_ids.include?(recording.recordable_id) }
      when "draft"
        hidden = published_ids + scheduled_ids
        list.reject { |recording| hidden.include?(recording.recordable_id) }
      else
        list
      end
    end

    def filter_query(list)
      return list if @query.blank?

      needle = @query.downcase
      list.select { |recording| title_for(recording).downcase.include?(needle) }
    end

    def title_for(recording)
      recordable = recording.recordable if recording.respond_to?(:recordable)
      recordable&.try(:title).presence || recording.try(:name).to_s
    end

    def published_ids
      @published_ids ||= ids_for(:published)
    end

    def scheduled_ids
      @scheduled_ids ||= ids_for(:scheduled)
    end

    def ids_for(scope_name)
      kit_ids = @recordings.filter_map { |recording| recording.recordable_id if recording.respond_to?(:recordable_id) }
      return [] if kit_ids.empty?

      PressKit.public_send(scope_name).where(id: kit_ids).pluck(:id)
    end
  end
end
