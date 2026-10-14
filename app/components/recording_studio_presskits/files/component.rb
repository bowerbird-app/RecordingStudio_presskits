# frozen_string_literal: true

module RecordingStudioPresskits
  class Files
    class Component < ViewComponent::Base
      def initialize(recording:)
        super()
        @recording = recording
      end

      def render?
        rows.any?
      end

      def rows
        @rows ||= DirectFiles.list(@recording).map { |item| row_for(item) }
      end

      private

      def row_for(item)
        presentation = FilePresentation.new(item.recordable)
        {
          id: item.id,
          name: presentation.name,
          description: presentation.description,
          meta: presentation.meta,
          icon: presentation.icon_name
        }
      end
    end
  end
end
