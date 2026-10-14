# frozen_string_literal: true

require "active_support/number_helper"

module RecordingStudioPresskits
  class FilePresentation
    ICONS = {
      "pdf" => "document-text",
      "doc" => "document-text",
      "docx" => "document-text",
      "xls" => "table-cells",
      "xlsx" => "table-cells",
      "csv" => "table-cells",
      "ppt" => "presentation-chart-bar",
      "pptx" => "presentation-chart-bar",
      "txt" => "document",
      "zip" => "archive-box"
    }.freeze

    def initialize(attachment)
      @attachment = attachment
    end

    def name
      @attachment.name.to_s.strip.presence || @attachment.original_filename.to_s
    end

    def description
      @attachment.description.to_s.strip.presence
    end

    def extension
      File.extname(@attachment.original_filename.to_s).delete(".").upcase.presence
    end

    def size_label
      bytes = @attachment.byte_size
      return if bytes.nil?

      ActiveSupport::NumberHelper.number_to_human_size(bytes, strip_insignificant_zeros: true)
    end

    def meta
      [extension, size_label].compact.join(" · ")
    end

    def icon_name
      ICONS.fetch(extension.to_s.downcase, "paper-clip")
    end
  end
end
