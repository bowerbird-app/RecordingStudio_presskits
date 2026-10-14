# frozen_string_literal: true

require_relative "api/access"
require "recording_studio_metrics"

module RecordingStudioPresskits
  module Metrics
    RESOURCE = :press_kits
    API = :operations
    EXPOSE = { api: [API] }.freeze

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
