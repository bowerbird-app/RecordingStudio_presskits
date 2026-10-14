# frozen_string_literal: true

module RecordingStudioPresskits
  class ImageFacts
    TYPE_LABELS = {
      "image/jpeg" => "JPG",
      "image/jpg" => "JPG",
      "image/png" => "PNG",
      "image/gif" => "GIF",
      "image/webp" => "WEBP",
      "image/avif" => "AVIF",
      "image/heic" => "HEIC",
      "image/heif" => "HEIC"
    }.freeze
    KNOWN_RATIOS = {
      "1:1" => 1.0,
      "4:5" => 4.0 / 5,
      "5:4" => 5.0 / 4,
      "3:2" => 3.0 / 2,
      "2:3" => 2.0 / 3,
      "16:9" => 16.0 / 9,
      "9:16" => 9.0 / 16,
      "3:4" => 3.0 / 4,
      "4:3" => 4.0 / 3,
      "2:1" => 2.0,
      "1:2" => 0.5
    }.freeze
    RATIO_TOLERANCE = 0.02

    def initialize(attachment)
      @attachment = attachment
    end

    def name
      @attachment&.try(:name).to_s.strip.presence
    end

    def meta
      return if width.nil? || height.nil?

      type = type_label
      return if type.blank?

      "#{type} · #{width}×#{height} · #{ratio_label}"
    end

    # The gallery caption is one muted line under FlatPack::Media.
    def caption
      [name, meta].compact.join(" · ")
    end

    def width
      pixels&.first
    end

    def height
      pixels&.last
    end

    private

    def pixels
      return @pixels if defined?(@pixels)

      file = @attachment&.try(:file)
      blob = file.blob if file.respond_to?(:attached?) && file.attached?
      @pixels = blob.present? ? ImagePixelSize.ensure_blob!(blob) : nil
    end

    def type_label
      raw = mime_type
      return if raw.blank?

      TYPE_LABELS[raw] || subtype_label(raw)
    end

    def mime_type
      @attachment&.try(:content_type).to_s.split(";").first.to_s.strip.downcase.presence
    end

    def subtype_label(raw)
      raw.split("/", 2).last.to_s.split("+", 2).first.to_s.upcase.presence
    end

    def ratio_label
      known_ratio || reduced_ratio
    end

    def known_ratio
      value = width.to_f / height
      label, ratio = KNOWN_RATIOS.min_by { |_name, known| (known - value).abs }
      label if (ratio - value).abs <= RATIO_TOLERANCE
    end

    def reduced_ratio
      divisor = width.gcd(height)
      "#{width / divisor}:#{height / divisor}"
    end
  end
end
