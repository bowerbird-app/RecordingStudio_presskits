# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionCountBadge
      def self.for(content)
        recordable = content&.recordable
        count = count_for(content, recordable)
        return if count.nil? || count.zero?

        FlatPack::Badge::Component.new(text: count.to_s, size: :sm)
      end

      def self.count_for(content, recordable)
        if recordable.is_a?(Images)
          DirectImages.list(content).size
        elsif recordable.is_a?(VideoSection)
          VideoSection.active_videos(content).size
        end
      end
      private_class_method :count_for
    end
  end
end
