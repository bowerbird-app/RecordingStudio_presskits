# frozen_string_literal: true

module RecordingStudioPresskits
  class HeaderAttributes
    class << self
      def from(submitted)
        copy(submitted).merge(brand(submitted)).merge(source(submitted))
      end

      def copy(submitted)
        {
          title: submitted[:title].to_s.strip,
          subtitle: submitted[:subtitle].to_s.strip.presence,
          description: submitted[:description].to_s.strip.presence
        }
      end

      def brand(submitted)
        return {} unless apply_brand?(submitted)
        return { brand_color: nil, font_family: nil } if press_center?(submitted)

        {
          brand_color: submitted[:brand_color],
          font_family: submitted[:font_family]
        }
      end

      def apply_brand?(submitted)
        submitted.key?(:brand_color) || submitted.key?(:font_family) || submitted.key?(:brand_source)
      end

      def press_center?(submitted)
        submitted[:brand_source].to_s == "press_center"
      end

      def source(submitted)
        value = submitted[:brand_source].to_s.presence
        return {} if value.blank?

        { brand_source: value }
      end

      def alert_for(error)
        messages = error.record.errors
        return messages.full_messages.to_sentence if messages[:base].any?
        return "Check the place. Something there is off." if error.record.is_a?(RecordingStudio::Location::Location)
        return "Keep that subtitle short. 120 characters is the limit." if messages[:subtitle].any?

        "Keep that description short. 280 characters is the limit."
      end
    end
  end
end
