# frozen_string_literal: true

module RecordingStudioPresskits
  module Cover
    class Company
      class << self
        def recording_for(recording)
          return if recording.blank? || !defined?(RecordingStudioCompany)

          root = recording.root_recording_or_self
          return if RecordingStudioCompany.allowance(root).blank?

          RecordingStudioCompany.company(root)
        rescue RecordingStudioCompany::ParentNotAllowed, RecordingStudioCompany::ManyCompaniesAllowed,
               RecordingStudioCompany::CompanyIntegrityError
          nil
        end

        def name_for(recording)
          recording_for(recording)&.recordable&.name
        end
      end
    end
  end
end
