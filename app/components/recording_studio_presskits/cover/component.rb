# frozen_string_literal: true

module RecordingStudioPresskits
  module Cover
    class Component < ViewComponent::Base
      include RecordingStudioCompany::DisplayHelper if defined?(RecordingStudioCompany::DisplayHelper)
      include RecordingStudioAttachable::ApplicationHelper if defined?(RecordingStudioAttachable::ApplicationHelper)
      include Byline

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
        hero? ? "auto" : "9 / 16"
      end

      def eyebrow
        I18n.t("recording_studio_presskits.cover.eyebrow")
      end

      def eyebrow_classes
        # Tailwind scans these literals: "text-3xl" "text-4xl"
        "font-normal leading-tight text-3xl md:text-4xl"
      end

      def eyebrow_style
        "color: color-mix(in oklab, #{text_color} 70%, transparent);"
      end

      def surface_classes
        # Tailwind scans these literals: "aspect-[9/16]" "max-w-xs" "justify-start" "max-w-3xl" "p-12" "md:p-24"
        if hero?
          "flex w-full flex-col justify-start rounded-none p-12 md:p-24"
        elsif preview?
          "flex aspect-[9/16] w-full flex-col justify-end p-6"
        else
          "flex aspect-[9/16] w-full flex-col justify-end p-5"
        end
      end

      def hero_copy_classes
        "flex max-w-3xl flex-col gap-3"
      end

      def wrapper_classes
        preview? ? "max-w-xs w-full overflow-hidden" : "h-full w-full overflow-hidden"
      end

      def surface_style
        rules = ["background-color: #{cover_color}", "color: #{text_color}"]
        rules << "aspect-ratio: #{cover_ratio}" unless hero?
        "#{rules.join('; ')};"
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
