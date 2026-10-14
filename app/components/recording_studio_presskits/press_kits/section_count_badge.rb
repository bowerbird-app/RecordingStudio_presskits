# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionCountBadge
      def self.for(content, accessible: false)
        recordable = content&.recordable
        count = count_for(content, recordable)
        return if count.nil? || count.zero?

        options = { text: count.to_s, size: :sm }
        label = accessible_name(recordable, count) if accessible
        options[:aria] = { label: label } if label.present?
        FlatPack::Badge::Component.new(**options)
      end

      def self.count_for(content, recordable)
        case recordable
        when Images
          DirectImages.list(content).size
        when VideoSection
          VideoSection.active_videos(content).size
        when Files
          DirectFiles.list(content).size
        end
      end

      def self.accessible_name(recordable, count)
        noun = count_noun(recordable)
        return if noun.blank?

        "#{count} #{noun.pluralize(count)}"
      end

      def self.count_noun(recordable)
        case recordable
        when Images then "image"
        when VideoSection then "video"
        when Files then "file"
        end
      end
      private_class_method :count_for, :accessible_name, :count_noun
    end
  end
end
