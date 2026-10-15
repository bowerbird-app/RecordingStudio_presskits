# frozen_string_literal: true

module RecordingStudioPresskits
  class HeaderAttributes
    class << self
      def from(submitted)
        copy(submitted).merge(brand(submitted)).merge(source(submitted)).merge(release_date(submitted))
      end

      def copy(submitted)
        %i[title subtitle description].each_with_object({}) do |key, fields|
          next unless submitted.key?(key)

          text = submitted[key].to_s.strip
          fields[key] = key == :title ? text : text.presence
        end
      end

      def brand(submitted)
        return {} unless apply_brand?(submitted)
        return cleared_brand if press_center?(submitted)

        {
          brand_color: submitted[:brand_color],
          font_family: submitted[:font_family],
          text_color: submitted[:text_color],
          corner_style: submitted[:corner_style]
        }
      end

      def cleared_brand
        { brand_color: nil, font_family: nil, text_color: nil, corner_style: nil }
      end

      def apply_brand?(submitted)
        submitted.key?(:brand_color) || submitted.key?(:font_family) ||
          submitted.key?(:text_color) || submitted.key?(:corner_style) ||
          submitted.key?(:brand_source)
      end

      def press_center?(submitted)
        submitted[:brand_source].to_s == "press_center"
      end

      def stored_source(recordable)
        names = %i[brand_color font_family text_color corner_style]
        names.any? { |name| recordable.public_send(name).present? } ? "custom" : "press_center"
      end

      def source(submitted)
        value = submitted[:brand_source].to_s.presence
        return {} if value.blank?

        { brand_source: value }
      end

      def release_date(submitted)
        return {} unless submitted.key?(:release_date)

        text = submitted[:release_date].to_s.strip
        return { release_date: nil } if text.blank?

        { release_date: Date.iso8601(text) }
      rescue Date::Error
        { release_date: nil }
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
