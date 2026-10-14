# frozen_string_literal: true

module RecordingStudioPresskits
  module Videos
    class DetailsComponent < ViewComponent::Base
      def initialize(video:)
        super()
        @video = video
      end

      def length_error
        messages = @video.errors[:duration]
        messages.to_sentence if messages.present?
      end

      def thumbnail_error
        messages = @video.errors[:thumbnail_url]
        messages.to_sentence if messages.present?
      end

      def length_name
        "#{@video.model_name.param_key}[duration]"
      end

      def thumbnail_name
        "#{@video.model_name.param_key}[thumbnail_url]"
      end
    end
  end
end
