# frozen_string_literal: true

module RecordingStudioPresskits
  # Duration and an optional thumbnail live on Recording Studio Video's table.
  # Press Kits adds the columns. Revise already copies that row, so a second
  # recording would only split the snapshot.
  module VideoDetails
    extend ActiveSupport::Concern

    def self.install!
      return unless defined?(RecordingStudioVideo::Video)
      return if self >= RecordingStudioVideo::Video

      RecordingStudioVideo::Video.include self
    end

    included do
      before_validation :normalize_presskit_video_details
      validate :duration_clock_is_valid
      validate :thumbnail_url_is_https
    end

    def duration
      return @duration_input if duration_invalid?

      VideoClock.format(duration_seconds)
    end

    def duration=(value)
      parsed = VideoClock.parse(value)
      if parsed == :invalid
        @duration_invalid = true
        @duration_input = value.to_s
        return
      end

      @duration_invalid = false
      @duration_input = nil
      self.duration_seconds = parsed
    end

    def duration_label
      VideoClock.format(duration_seconds)
    end

    def provider_name
      case try(:provider).to_s
      when "youtube" then "YouTube"
      when "vimeo" then "Vimeo"
      when "" then nil
      else try(:provider).to_s.tr("_", " ").split.map(&:capitalize).join(" ").presence
      end
    end

    def watch_url
      canonical = try(:canonical_url).to_s.strip
      return canonical if canonical.present?

      try(:url).to_s.strip.presence
    end

    def poster_url
      override = thumbnail_url.to_s.strip.presence
      return override if override

      VideoPoster.url_for(try(:url))
    end

    private

    def duration_invalid?
      defined?(@duration_invalid) && @duration_invalid
    end

    def normalize_presskit_video_details
      self.thumbnail_url = thumbnail_url.to_s.strip.presence
    end

    def duration_clock_is_valid
      return unless duration_invalid?

      errors.add(:duration, I18n.t("recording_studio_presskits.videos.length_error"))
    end

    def thumbnail_url_is_https
      value = thumbnail_url.to_s.strip
      return if value.blank?
      return if https_thumbnail?(value)

      errors.add(:thumbnail_url, I18n.t("recording_studio_presskits.videos.thumbnail_error"))
    end

    def https_thumbnail?(value)
      uri = URI.parse(value)
      (uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)) && uri.host.present? && uri.userinfo.nil?
    rescue URI::InvalidURIError
      false
    end
  end
end
