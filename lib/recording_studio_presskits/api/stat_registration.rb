# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module StatRegistration
      def register_stats!
        register_stat
        register_stats_section
      end

      private

      def register_stat
        register_type(
          "RecordingStudioPresskits::Stat",
          operations: %i[index show create update destroy],
          serializer: StatPayload.method(:for),
          output_keys: stat_keys,
          writable_attributes: stat_keys
        )
      end

      def stat_keys
        %i[label value unit description icon]
      end

      def register_stats_section
        register_type(
          "RecordingStudioPresskits::StatsSection",
          operations: %i[index show],
          capability_actions: %i[reorder_stats],
          relationships: { stats: stats_relationship }
        )
      end

      def stats_relationship
        child_collection(
          "RecordingStudioPresskits::Stat",
          serializer: StatPayload.method(:for),
          output_keys: stat_keys,
          endpoints: %i[index show create update destroy],
          description: "Stats in this section"
        )
      end
    end
  end
end
