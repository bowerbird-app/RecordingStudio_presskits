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
          serializer: ->(recordable, context: nil, **) { StatPayload.for(recordable, context: context) },
          output_keys: stat_keys,
          writable_attributes: stat_keys
        )
      end

      def stat_keys
        %i[label value unit description]
      end

      def register_stats_section
        register_type(
          "RecordingStudioPresskits::StatsSection",
          operations: %i[index show],
          serializer: stats_section_serializer,
          output_keys: %i[stats]
        )
      end

      def stats_section_serializer
        lambda { |recordable, recording: nil, context: nil, **|
          source = Exposure.named_recording(recording: recording, context: context)
          source ||= RecordingStudio::Recording.find_by(recordable: recordable)
          StatPayload.for_recording(source, context: context)
        }
      end
    end
  end
end
