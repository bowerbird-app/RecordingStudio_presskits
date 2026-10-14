# frozen_string_literal: true

module RecordingStudioPresskits
  # The "published" definition shared by press_kits.published_over_time and the press kits
  # index filters: a kit whose current (kept) Publishable child is in the published state
  # with a publish_at.
  module PublishedKits
    PUBLISHABLE_TYPE = "RecordingStudioPublishable::Publishable"

    module_function

    # Index list filters. publish_from/publish_to bound publish_at as
    # publish_from <= publish_at < publish_to (the metric's window). Either bound implies published.
    def filter_index(relation, published: false, publish_from: nil, publish_to: nil)
      return relation unless published || publish_from || publish_to

      relation.where(id: ids(publish_from: publish_from, publish_to: publish_to))
    end

    def ids(publish_from: nil, publish_to: nil)
      table = RecordingStudio::Recording.table_name
      scope = RecordingStudio::Recording.unscoped
                                        .joins(join_sql(table))
                                        .where("publishables.status = 'published'")
                                        .where.not(publishables: { publish_at: nil })
      scope = scope.where(publishables: { publish_at: publish_from.. }) if publish_from
      scope = scope.where(publishables: { publish_at: ...publish_to }) if publish_to
      scope.select("#{table}.id")
    end

    def join_sql(table)
      children = RecordingStudio::Recording.unscoped
                                           .where(RecordingStudio::Recording.recording_studio_trashable_kept_sql)
                                           .where(recordable_type: PUBLISHABLE_TYPE)
                                           .select(:parent_recording_id, :recordable_id)
      "INNER JOIN (#{children.to_sql}) publishable_children " \
        "ON publishable_children.parent_recording_id = #{table}.id " \
        "INNER JOIN recording_studio_publishable_publishables publishables " \
        "ON publishables.id = publishable_children.recordable_id"
    end
  end
end
