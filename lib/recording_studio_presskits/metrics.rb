# frozen_string_literal: true

require_relative "api/access"
require "recording_studio_metrics"

module RecordingStudioPresskits
  module Metrics
    RESOURCE = :press_kits
    API = :operations
    EXPOSE = { api: [API] }.freeze
    PUBLISHABLE_TYPE = "RecordingStudioPublishable::Publishable"
    PUBLISHED_DESCRIPTION = "Live press kits by the publish_at of their current publish settings " \
                            "(set to now on Publish, or the scheduled time). " \
                            "Kits unpublished since then are not counted."

    module_function

    def register!
      RecordingStudioMetrics.register(
        RESOURCE,
        model: RecordingStudio::Recording,
        blast_radius: :site,
        scope: method(:live_kits),
        api_authorize: ->(context) { RecordingStudioPresskits::Api::Access.can_view?(context) }
      ) do
        RecordingStudioPresskits::Metrics.define_core(self)
        RecordingStudioPresskits::Metrics.define_section_types(self)
      end
    end

    def define_core(dsl)
      dsl.count :total, title: "Live press kits", expose: EXPOSE
      dsl.timeseries :created_over_time,
                     title: "Press kits created over time",
                     field: :created_at,
                     expose: EXPOSE
      define_published(dsl)
    end

    def define_published(dsl)
      dsl.timeseries :published_over_time,
                     title: "Press kits published over time",
                     description: PUBLISHED_DESCRIPTION,
                     unit: "count",
                     field: :published_at,
                     scope: RecordingStudioPresskits::Metrics.method(:published_kits),
                     expose: EXPOSE
    end

    def define_section_types(dsl)
      dsl.custom :by_section_type,
                 result_type: :breakdown,
                 title: "Sections by type",
                 expose: EXPOSE,
                 &section_type_calculator
    end

    def live_kits(relation)
      relation.where(RecordingStudio::Recording.recording_studio_trashable_kept_sql).where(
        recordable_type: RecordingStudioPresskits.press_kit_type_name
      )
    end

    # Live kits whose current Publishable child is in the published state, with
    # that row's publish_at exposed as published_at so the stock timeseries
    # calculator can bucket and window on it.
    def published_kits(relation)
      table = RecordingStudio::Recording.table_name
      sql = live_kits(relation.unscope(:select))
            .joins(publishable_join_sql(table))
            .where("publishables.status = 'published' AND publishables.publish_at IS NOT NULL")
            .select("#{table}.*", "publishables.publish_at AS published_at")
      RecordingStudio::Recording.unscoped.from("(#{sql.to_sql}) #{table}")
    end

    def publishable_join_sql(table)
      children = RecordingStudio::Recording.unscoped
                                           .where(RecordingStudio::Recording.recording_studio_trashable_kept_sql)
                                           .where(recordable_type: PUBLISHABLE_TYPE)
                                           .select(:parent_recording_id, :recordable_id)
      "INNER JOIN (#{children.to_sql}) publishable_children " \
        "ON publishable_children.parent_recording_id = #{table}.id " \
        "INNER JOIN recording_studio_publishable_publishables publishables " \
        "ON publishables.id = publishable_children.recordable_id"
    end

    def section_type_calculator
      lambda do |relation, _context|
        rows = live_section_contents(relation).group(:recordable_type).distinct.count.map do |key, value|
          { key: key, value: value }
        end
        rows.sort_by { |row| row[:key].to_s }
      end
    end

    def live_section_contents(kits)
      sql = RecordingStudio::Recording.recording_studio_trashable_kept_sql
      sections = RecordingStudio::Recording.where(sql).where(
        recordable_type: KitSection.name,
        parent_recording_id: kits.select(:id)
      )
      RecordingStudio::Recording.where(sql).where(
        parent_recording_id: sections.select(:id),
        recordable_type: RecordingStudioPresskits.section_types
      )
    end
  end
end
