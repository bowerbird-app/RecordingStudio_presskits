# frozen_string_literal: true

module RecordingStudioPresskits
  module Cover
    class Component < ViewComponent::Base
      SIZES = %i[card preview hero].freeze

      def initialize(recording: nil, title: nil, description: nil, cover_color: nil, # rubocop:disable Metrics/ParameterLists
                     cover_style: nil, size: :card, href: nil, id: nil)
        super()
        @recording = recording
        @title = title
        @description = description
        @cover_color = cover_color
        @cover_style = cover_style
        @size = SIZES.include?(size&.to_sym) ? size.to_sym : :card
        @href = href
        @id = id
      end

      def title
        @title.presence || recordable&.try(:title).presence || "Press kit"
      end

      def description
        text = @description.nil? ? recordable&.try(:description) : @description
        text.to_s.strip.presence
      end

      def cover_color
        Hex.normalize(@cover_color.presence || recordable&.try(:resolved_cover_color)) ||
          RecordingStudioPresskits.default_cover_color
      end

      def cover_style
        @cover_style.presence || recordable&.try(:resolved_cover_style).presence || "color"
      end

      def text_color
        Contrast.text_on(cover_color)
      end

      def card?
        @size == :card
      end

      def preview?
        @size == :preview
      end

      def hero?
        @size == :hero
      end

      def href
        @href.presence
      end

      def card_style
        return :interactive if href.present?
        return :flat if hero?

        :default
      end

      def heading_variant
        hero? ? :h1 : :h2
      end

      def surface_classes
        if hero?
          "flex min-h-80 w-full flex-col justify-end p-8 md:min-h-96 md:p-12"
        elsif preview?
          "flex aspect-video w-full flex-col justify-end p-6"
        else
          "flex aspect-video h-full w-full flex-col justify-end p-5"
        end
      end

      def wrapper_id
        return @id if @id.present?
        return "presskits-cover-hero" if hero?
        return "presskits-cover-preview" if preview?

        nil
      end

      private

      def recordable
        @recording&.recordable
      end
    end
  end
end
