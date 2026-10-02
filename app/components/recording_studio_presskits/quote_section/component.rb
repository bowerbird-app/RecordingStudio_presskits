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

      def attribution(recordable)
        parts = [recordable.role, recordable.organisation]
        parts.filter_map { |value| value.to_s.strip.presence }.join(", ")
      end

      def avatar_url(quote_recording)
        file = avatar_file(quote_recording)
        return unless file&.attached?

        helpers.main_app.url_for(file)
      end

      def avatar_alt(recordable)
        recordable.name.to_s.strip.presence || "Quote"
      end

      private

      def ordered_quotes
        @recording.recording_studio_orderable_children.reject { |child| skip?(child) }
      end

      def skip?(child)
        child.trashed_at.present? || !child.recordable.is_a?(Quote)
      end

      def avatar_file(quote_recording)
        quote_recording.images(per_page: 1).first&.recordable&.file
      end
    end
  end
end
