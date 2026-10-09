# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionPickerComponent < ViewComponent::Base
      def initialize(items:, add_path:, after_recording_id: nil)
        super()
        @items = Array(items)
        @add_path = add_path
        @after_recording_id = after_recording_id
      end

      def add_path_for(type_name)
        uri = @add_path.to_s
        query = ["type=#{ERB::Util.url_encode(type_name)}"]
        query << "after_recording_id=#{ERB::Util.url_encode(@after_recording_id)}" if @after_recording_id.present?
        separator = uri.include?("?") ? "&" : "?"
        "#{uri}#{separator}#{query.join("&")}"
      end
    end
  end
end
