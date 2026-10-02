# frozen_string_literal: true

module RecordingStudioPresskits
  class QuoteSection
    class Component < ViewComponent::Base
      def initialize(recording:)
        super()
        @recording = recording
      end

      def quotes
        ordered_quotes.select { |child| child.recordable.body.to_s.strip.present? }
      end

      def cite(recordable)
        [recordable.name, recordable.role, recordable.organisation].filter_map { |value|
          value.to_s.strip.presence
        }.join(", ")
      end

      # FlatPack's border-l-[var(--quote-border-width)] compiles as a color, so the
      # left rule never paints. These figure classes restore the quote tokens.
      def quote_frame_classes
        [
          "[&>blockquote]:border-l-[length:var(--quote-border-width)]",
          "[&>blockquote]:border-solid",
          "[&>blockquote]:border-[var(--quote-border-color)]"
        ].join(" ")
      end

      private

      def ordered_quotes
        @recording.recording_studio_orderable_children.reject { |child| skip?(child) }
      end

      def skip?(child)
        child.trashed_at.present? || !child.recordable.is_a?(Quote)
      end
    end
  end
end
