# frozen_string_literal: true

module RecordingStudioPresskits
  class HeaderAttributes
    AUTO_TEXT = "auto"

    class << self
      def from(submitted)
        {
          title: submitted[:title].to_s.strip,
          description: submitted[:description].to_s.strip.presence,
          cover_style: submitted[:cover_style].to_s.strip.presence,
          cover_color: submitted[:cover_color].to_s.strip.presence,
          cover_text_color: text_color(submitted)
        }
      end

      def text_color(submitted)
        choice = submitted[:cover_text_color].to_s.strip
        return if choice == AUTO_TEXT
        return submitted[:cover_text_swatch].to_s.strip.presence if choice.blank?

        choice.presence
      end
    end
  end
end
