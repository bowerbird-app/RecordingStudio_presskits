# frozen_string_literal: true

module RecordingStudioPresskits
  module PressKits
    class SectionDropdownComponent < ViewComponent::Base
      def initialize(items:, add_path:, after_recording_id: nil, compact: false)
        super()
        @items = Array(items)
        @add_path = add_path
        @after_recording_id = after_recording_id
        @compact = compact
      end

      def add_path_for(type_name)
        uri = @add_path.to_s
        query = ["type=#{ERB::Util.url_encode(type_name)}"]
        query << "after_recording_id=#{ERB::Util.url_encode(@after_recording_id)}" if @after_recording_id.present?
        separator = uri.include?("?") ? "&" : "?"
        "#{uri}#{separator}#{query.join('&')}"
      end

      def button_text
        return if @compact

        I18n.t("recording_studio_presskits.editor.add_section")
      end

      def dropdown_id
        @compact ? "presskits-section-dropdown-after-#{@after_recording_id}" : "presskits-section-dropdown"
      end
    end
  end
end
