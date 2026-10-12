# frozen_string_literal: true

module RecordingStudioPresskits
  class HeaderAttributes
    AUTO_TEXT = "auto"

    class << self
      def from(submitted)
        copy(submitted).merge(cover(submitted))
      end

      def copy(submitted)
        {
          title: submitted[:title].to_s.strip,
          subtitle: submitted[:subtitle].to_s.strip.presence,
          description: submitted[:description].to_s.strip.presence
        }
      end

      def cover(submitted)
        {
          cover_style: submitted[:cover_style].to_s.strip.presence,
          cover_color: submitted[:cover_color].to_s.strip.presence,
          cover_text_color: text_color(submitted)
        }
      end

      def alert_for(error)
        messages = error.record.errors
        return "Pick a colour we can actually paint." if messages[:cover_color].any?
        return "Pick a text colour we can actually paint." if messages[:cover_text_color].any?
        return "That cover style is not ready yet." if messages[:cover_style].any?
        return "Check the place. Something there is off." if error.record.is_a?(RecordingStudio::Location::Location)
        return "Keep that subtitle short. 120 characters is the limit." if messages[:subtitle].any?

        "Keep that description short. 280 characters is the limit."
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
