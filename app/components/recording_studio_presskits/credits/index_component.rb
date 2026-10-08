# frozen_string_literal: true

module RecordingStudioPresskits
  module Credits
    class IndexComponent < ViewComponent::Base
      def initialize(credit_recordings:, new_path:, edit_path:)
        super()
        @credit_recordings = credit_recordings
        @new_path = new_path
        @edit_path = edit_path
      end

      def rows
        @credit_recordings
      end

      def edit_href(recording)
        @edit_path.call(recording)
      end

      def usual_role(recording)
        recording.recordable.usual_role.to_s.strip.presence
      end

      def url_cell(recording)
        url = FlatPack::AttributeSanitizer.sanitize_url(recording.recordable.url)
        return if url.blank?

        helpers.link_to(recording.recordable.url.to_s.strip, url, target: "_blank", rel: "noopener noreferrer")
      end
    end
  end
end
