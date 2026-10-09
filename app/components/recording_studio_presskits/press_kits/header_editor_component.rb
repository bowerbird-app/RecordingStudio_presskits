# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class HeaderEditorComponent < ViewComponent::Base
      def initialize(press_kit_recording:, title:, description:, cover_style: nil, # rubocop:disable Metrics/ParameterLists
                     cover_color: nil, cover_text_color: nil)
        super()
        @press_kit_recording = press_kit_recording
        @title = title
        @description = description
        @cover_style = cover_style
        @cover_color = cover_color
        @cover_text_color = cover_text_color
      end

      def header_title
        @title.to_s
      end

      def header_description
        @description.to_s
      end

      def header_cover_style
        @cover_style.to_s.strip.presence || "color"
      end

      def header_cover_color
        Cover::Hex.normalize(@cover_color).presence ||
          @press_kit_recording&.recordable&.try(:resolved_cover_color) ||
          RecordingStudioPresskits.default_cover_color
      end

      def header_cover_text_color
        Cover::Hex.normalize(@cover_text_color)
      end

      def header_cover_text_value
        header_cover_text_color.presence || auto_text_value
      end

      def auto_text_value
        RecordingStudioPresskits::Cover::Palette::AUTO_VALUE
      end

      def header_text_swatch_color
        header_cover_text_color.presence ||
          Cover::Contrast.text_on(header_cover_color)
      end

      def auto_text_color?
        header_cover_text_color.blank?
      end

      def low_contrast_text?
        Cover::Contrast.low_contrast?(header_cover_color, header_text_swatch_color)
      end

      def cancel_path
        helpers.edit_press_kit_path(@press_kit_recording)
      end

      def any_cover_color?
        RecordingStudioPresskits.any_cover_color?
      end

      def any_cover_text_color?
        RecordingStudioPresskits.any_cover_text_color?
      end

      def cover_text_auto?
        RecordingStudioPresskits.cover_text_auto?
      end

      def cover_options
        with_orphaned_colour(
          RecordingStudioPresskits.cover_palette.options,
          header_cover_color,
          RecordingStudioPresskits.cover_palette
        )
      end

      def cover_text_options
        options = RecordingStudioPresskits.cover_text_palette.options(auto: cover_text_auto?)
        with_orphaned_colour(options, header_cover_text_color, RecordingStudioPresskits.cover_text_palette)
      end

      private

      def with_orphaned_colour(options, current, palette)
        return options if current.blank?
        return options if options.any? { |option| option[:value] == current }

        options + [{ label: palette.label_for(current), value: current }]
      end
    end
  end
end
