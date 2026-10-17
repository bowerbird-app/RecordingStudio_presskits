# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    class MenuPayload
      KEYS = %i[layout show_counts show_icons items].freeze

      def self.for(recordable, context: nil, recording: nil, **)
        source = Exposure.named_recording(recording: recording, context: context, recordable: recordable)
        return KEYS.index_with { nil } if Exposure.withhold?(context, source)

        {
          layout: recordable.layout,
          show_counts: recordable.show_counts,
          show_icons: recordable.show_icons,
          items: recordable.items.is_a?(Hash) ? recordable.items : {}
        }
      end
    end
  end
end
