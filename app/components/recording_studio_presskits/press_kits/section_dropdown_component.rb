# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionDropdownComponent < ViewComponent::Base
      def initialize(items:, add_path:)
        super()
        @items = Array(items)
        @add_path = add_path
      end

      def add_path_for(type_name)
        separator = @add_path.to_s.include?("?") ? "&" : "?"
        "#{@add_path}#{separator}type=#{ERB::Util.url_encode(type_name)}"
      end
    end
  end
end
