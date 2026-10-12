# frozen_string_literal: true

module RecordingStudioPresskits
  class KitSetting < ApplicationRecord
    self.table_name = "recording_studio_presskits_kit_settings"

    FALLBACKS = %w[preview hidden].freeze

    validates :recording_id, presence: true
    validates :visibility_fallback, inclusion: { in: FALLBACKS }
  end
end
