# frozen_string_literal: true

module RecordingStudioPresskits
  class StatsSection
    class CopyButtonComponent < ViewComponent::Base
      def initialize(text:)
        super()
        @text = text
      end

      def call
        render button
      end

      private

      def button
        FlatPack::Button::Component.new(
          text: "Copy",
          icon: "clipboard-document",
          style: :default,
          type: "button",
          data: copy_data
        )
      end

      def copy_data
        {
          controller: "recording-studio-presskits--copy-text",
          recording_studio_presskits__copy_text_text_value: @text,
          action: "click->recording-studio-presskits--copy-text#copy"
        }
      end
    end
  end
end
