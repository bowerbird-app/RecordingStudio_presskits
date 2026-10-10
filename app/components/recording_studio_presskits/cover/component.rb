# frozen_string_literal: true

module RecordingStudioPresskits
  module Cover
    class Component < ViewComponent::Base
      SIZES = %i[card preview hero].freeze

      def initialize(recording: nil, title: nil, description: nil, cover_color: nil, # rubocop:disable Metrics/ParameterLists
                     cover_style: nil, cover_text_color: nil, size: :card, href: nil, id: nil)
        super()
        @recording = recording
        @title = title
        @description = description
        @cover_color = cover_color
        @cover_style = cover_style
        @cover_text_color = cover_text_color
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
        Hex.normalize(@cover_text_color.presence || recordable&.try(:resolved_cover_text_color)) ||
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
        :h1
      end

      def cover_ratio
        hero? ? "21 / 9" : "9 / 16"
      end

      def surface_classes
        # Tailwind scans these literals: "aspect-[9/16]" "aspect-[21/9]" "max-w-xs" "justify-start" "max-w-2xl"
        if hero?
          "flex aspect-[21/9] min-h-64 w-full flex-col justify-start rounded-none p-8 md:p-12"
        elsif preview?
          "flex aspect-[9/16] w-full flex-col justify-end p-6"
        else
          "flex aspect-[9/16] w-full flex-col justify-end p-5"
        end
      end

      def hero_copy_classes
        "max-w-2xl"
      end

      def wrapper_classes
        preview? ? "max-w-xs w-full overflow-hidden" : "h-full w-full overflow-hidden"
      end

      def surface_style
        "background-color: #{cover_color}; color: #{text_color}; aspect-ratio: #{cover_ratio};"
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
