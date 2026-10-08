# frozen_string_literal: true

module RecordingStudioPresskits
  class CreditLine < ApplicationRecord
    self.table_name = "recording_studio_credit_lines"

    recording_studio_recordable label: "Credit",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::CreditsSection"]

    include RecordingStudio::Capabilities::Trashable.to

    validates :credit_recording_id, presence: true

    before_validation :clear_blank_role

    def title
      role.to_s.strip.presence || "Credit"
    end

    private

    def clear_blank_role
      self.role = role.to_s.strip.presence
    end
  end
end
