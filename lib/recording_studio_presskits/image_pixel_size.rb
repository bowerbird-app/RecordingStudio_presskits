# frozen_string_literal: true

module RecordingStudioPresskits
  # JPEG and PNG pixel size, for blobs ActiveStorage marked analyzed without
  # width and height. Hosts do not need libvips for the gallery caption.
  class ImagePixelSize
    SOF_MARKERS = [
      0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF
    ].freeze
    STANDALONE_MARKERS = [0x01, 0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9].freeze
    STOP_MARKERS = [0xDA, 0xD9].freeze

    class << self
      def read(io)
        bytes = io&.read
        return if bytes.nil? || bytes.bytesize < 24

        return png_size(bytes) if bytes.start_with?("\x89PNG".b)
        return jpeg_size(bytes) if bytes.start_with?("\xFF\xD8".b)

        nil
      end

      def from_blob(blob)
        return if blob.blank?

        blob.open { |file| read(file) }
      rescue StandardError
        nil
      end

      def ensure_blob!(blob)
        stored(blob) || after_analyze(blob) || measured(blob)
      rescue StandardError
        nil
      end

      def after_analyze(blob)
        blob.analyze if blob.respond_to?(:analyze)
        stored(blob)
      end

      def measured(blob)
        pair = from_blob(blob)
        return if pair.blank?

        blob.update!(metadata: blob.metadata.merge("width" => pair[0], "height" => pair[1]))
        pair
      end

      def stored(blob)
        meta = blob.respond_to?(:metadata) ? blob.metadata : nil
        return unless meta.is_a?(Hash)

        width = positive(meta["width"] || meta[:width])
        height = positive(meta["height"] || meta[:height])
        return unless width && height

        [width, height]
      end

      private

      def png_size(bytes)
        return unless bytes.byteslice(12, 4) == "IHDR"

        width = bytes.byteslice(16, 4)&.unpack1("N")
        height = bytes.byteslice(20, 4)&.unpack1("N")
        pair(width, height)
      end

      def jpeg_size(bytes)
        index = 2
        while (step = jpeg_step(bytes, index))
          return step[:size] if step[:size]
          break unless step[:index]

          index = step[:index]
        end
        nil
      end

      def jpeg_step(bytes, index)
        return if index >= bytes.bytesize - 8
        return unless bytes.getbyte(index) == 0xFF

        marker_index = skip_fill(bytes, index + 1)
        marker_step(bytes, bytes.getbyte(marker_index), marker_index + 1)
      end

      def marker_step(bytes, marker, index)
        return { size: pair_at(bytes, index) } if SOF_MARKERS.include?(marker)
        return { index: nil } if STOP_MARKERS.include?(marker)
        return { index: index } if STANDALONE_MARKERS.include?(marker)

        segment_step(bytes, index)
      end

      def segment_step(bytes, index)
        length = bytes.byteslice(index, 2)&.unpack1("n")
        return { index: nil } if length.nil? || length < 2

        { index: index + length }
      end

      def skip_fill(bytes, index)
        index += 1 while bytes.getbyte(index) == 0xFF
        index
      end

      def pair_at(bytes, index)
        height = bytes.byteslice(index + 3, 2)&.unpack1("n")
        width = bytes.byteslice(index + 5, 2)&.unpack1("n")
        pair(width, height)
      end

      def pair(width, height)
        return unless positive(width) && positive(height)

        [width, height]
      end

      def positive(value)
        number = Integer(value)
        number if number.positive?
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
