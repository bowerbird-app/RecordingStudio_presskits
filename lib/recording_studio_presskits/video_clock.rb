# frozen_string_literal: true

module RecordingStudioPresskits
  # Length is typed as m:ss and stored as whole seconds.
  module VideoClock
    PATTERN = /\A(\d+):([0-5]\d)\z/

    def self.parse(value)
      text = value.to_s.strip
      return if text.blank?

      match = PATTERN.match(text)
      return :invalid unless match

      (match[1].to_i * 60) + match[2].to_i
    end

    def self.format(seconds)
      return if seconds.nil?

      total = Integer(seconds)
      return if total.negative?

      minutes, secs = total.divmod(60)
      "#{minutes}:#{secs.to_s.rjust(2, '0')}"
    end
  end
end
