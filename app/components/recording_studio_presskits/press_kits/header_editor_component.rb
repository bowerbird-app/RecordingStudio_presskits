# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class HeaderEditorComponent < ViewComponent::Base
      def initialize(press_kit_recording:, title:, description:, cover_style: nil, cover_color: nil)
        super()
        @press_kit_recording = press_kit_recording
        @title = title
        @description = description
        @cover_style = cover_style
        @cover_color = cover_color
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

      def cancel_path
        helpers.edit_press_kit_path(@press_kit_recording)
      end

      def any_cover_color?
        RecordingStudioPresskits.any_cover_color?
      end

      def cover_options
        options = RecordingStudioPresskits.cover_palette.options
        current = header_cover_color
        return options if options.any? { |option| option[:value] == current }

        options + [{ label: RecordingStudioPresskits.cover_palette.label_for(current), value: current }]
      end
    end
  end
end
