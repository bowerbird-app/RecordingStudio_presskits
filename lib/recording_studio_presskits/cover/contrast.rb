# frozen_string_literal: true

module RecordingStudioPresskits
  module Cover
    class Contrast
      LIGHT = "#F8FAFC"
      DARK = "#111827"
      AA_RATIO = 4.5

      def self.text_on(background)
        hex = Hex.normalize(background)
        return DARK unless hex

        contrast(hex, LIGHT) >= contrast(hex, DARK) ? LIGHT : DARK
      end

      def self.low_contrast?(background, foreground)
        bg = Hex.normalize(background)
        fg = Hex.normalize(foreground)
        return false unless bg && fg

        contrast(bg, fg) < AA_RATIO
      end

      def self.contrast(one, two)
        lighter, darker = [luminance(one), luminance(two)].minmax.reverse
        (lighter + 0.05) / (darker + 0.05)
      end

      def self.luminance(hex)
        red, green, blue = Hex.rgb(hex).map { |channel| linearize(channel / 255.0) }
        (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
      end

      def self.linearize(channel)
        return channel / 12.92 if channel <= 0.03928

        ((channel + 0.055) / 1.055)**2.4
      end
    end
  end
end
