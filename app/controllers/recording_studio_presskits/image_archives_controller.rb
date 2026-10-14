# frozen_string_literal: true

module RecordingStudioPresskits
  class ImageArchivesController < ActionController::Base
    include Devise::Controllers::Helpers if defined?(Devise::Controllers::Helpers)

    def show
      content = images_content
      kit = press_kit_for(content)
      return head :not_found unless kit && full_kit?(kit)

      send_archive(content)
    end

    private

    def images_content
      recording = RecordingStudio::Recording.find_by(id: params[:id])
      return unless recording&.recordable.is_a?(Images)
      return if recording.respond_to?(:trashed?) && recording.trashed?

      recording
    end

    def send_archive(content)
      files = ImagesArchive.files_for(content)
      return head :not_found if files.empty?

      send_data archive_bytes(files),
                filename: ImagesArchive.filename_for(content),
                type: "application/zip",
                disposition: "attachment"
    end

    def archive_bytes(files)
      payload = +""
      RecordingStudioDownloadable::ZipBuilder.new(files).write { |io| payload = io.read }
      payload
    end

    def press_kit_for(content)
      section = live_section(content)
      kit = section&.parent_recording
      kit if live_press_kit?(kit)
    end

    def live_section(content)
      section = content&.parent_recording
      return if section.blank? || !section.recordable.is_a?(KitSection)
      return if trashed?(section)

      section
    end

    def live_press_kit?(kit)
      kit&.recordable.is_a?(PressKit) && !trashed?(kit)
    end

    def trashed?(recording)
      recording.respond_to?(:trashed?) && recording.trashed?
    end

    def full_kit?(kit)
      assign_visitor
      Visibility.presentation_for(actor: visitor, kit: kit, purpose: :public) == :full
    end

    def assign_visitor
      return unless defined?(Current) && Current.respond_to?(:actor=)

      Current.actor = visitor
    end

    def visitor
      return current_user if respond_to?(:current_user, true)

      nil
    end
  end
end
