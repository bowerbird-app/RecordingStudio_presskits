# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionHeadingComponent < ViewComponent::Base
      def initialize(title:, subtitle: nil, size: :lg, spacing: :lg, level: :h2, anchor_link: true) # rubocop:disable Metrics/ParameterLists
        super()
        @title = title
        @subtitle = subtitle
        @size = size
        @spacing = spacing
        @level = level
        @anchor_link = anchor_link
      end

      def render?
        @title.to_s.strip.present? || @subtitle.to_s.strip.present?
      end
    end
  end
end
