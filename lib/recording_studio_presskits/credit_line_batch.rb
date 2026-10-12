# frozen_string_literal: true

require "active_model"

module RecordingStudioPresskits
  class CreditLineBatch
    include ActiveModel::Model

    class << self
      def model_name
        ActiveModel::Name.new(self, nil, "CreditLines")
      end

      def for_section(section_recording)
        new(credit_lines: Credits.lines_for(section_recording).map { |line| LineDraft.from(line) })
      end

      def blank_draft
        LineDraft.new
      end
    end

    attr_reader :credit_lines

    def initialize(credit_lines: [])
      @credit_lines = credit_lines
    end

    def credit_lines_attributes=(rows)
      @submitted_rows = rows
    end

    class LineDraft
      include ActiveModel::Model

      attr_accessor :id, :name, :url, :role

      def self.from(line)
        recordable = line.recordable
        new(
          id: line.id,
          name: recordable.name,
          url: recordable.url,
          role: recordable.role
        )
      end

      def persisted?
        id.present?
      end
    end
  end
end
