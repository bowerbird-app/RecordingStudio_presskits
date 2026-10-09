# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionPickerComponent < ViewComponent::Base
      def initialize(items:, add_path:)
        super()
        @items = Array(items)
        @add_path = add_path
      end

      def add_path_for(type_name)
        uri = @add_path.to_s
        query = "type=#{ERB::Util.url_encode(type_name)}"
        separator = uri.include?("?") ? "&" : "?"
        "#{uri}#{separator}#{query}"
      end
    end
  end
end
