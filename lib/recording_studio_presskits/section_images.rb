# frozen_string_literal: true

module RecordingStudioPresskits
  class SectionImages
    Result = Struct.new(:ok, :error, :placed, :skipped, keyword_init: true) do
      def success?
        ok
      end

      def failure?
        !ok
      end
    end

    def self.place(images_recording:, attachment_recording:, actor:)
      new(images_recording, actor).place(attachment_recording)
    end

    def self.place_many(images_recording:, attachment_recordings:, actor:)
      new(images_recording, actor).place_many(attachment_recordings)
    end

    def self.upload_and_place(images_recording:, actor:, library_recording: nil, **upload)
      new(images_recording, actor).upload_and_place(library_recording: library_recording, **upload)
    end

    def self.remove(images_recording:, placement_recording:, actor:)
      new(images_recording, actor).remove(placement_recording)
    end

    def initialize(images_recording, actor)
      @images_recording = images_recording
      @actor = actor
    end

    def place(attachment_recording)
      return missing_parent unless @images_recording
      return already_in_section if LibraryImages.already_placed?(@images_recording, attachment_recording)

      call_place(attachment_recording)
    end

    def place_many(attachment_recordings)
      return missing_parent unless @images_recording

      placed = []
      skipped = 0
      Array(attachment_recordings).compact.each do |attachment|
        if LibraryImages.already_placed?(@images_recording, attachment)
          skipped += 1
          next
        end

        result = call_place(attachment)
        return result if result.failure?

        placed << result.placed
      end

      Result.new(ok: true, placed: placed, skipped: skipped)
    end

    def upload_and_place(library_recording: nil, **upload)
      return missing_parent unless @images_recording

      result = RecordingStudioAttachable::Services::UploadToLibraryAndPlace.call(
        parent_recording: @images_recording,
        actor: @actor,
        library_recording: library_recording || default_library,
        **upload
      )
      service_result(result)
    end

    def remove(placement_recording)
      return missing_parent unless @images_recording

      result = RecordingStudioAttachable::Services::RemovePlacement.call(
        parent_recording: @images_recording,
        placement_recording: placement_recording,
        actor: @actor
      )
      service_result(result)
    end

    private

    def call_place(attachment_recording)
      result = RecordingStudioAttachable::Services::PlaceLibraryImage.call(
        parent_recording: @images_recording,
        attachment_recording: attachment_recording,
        actor: @actor
      )
      service_result(result)
    end

    def service_result(result)
      if result.success?
        Result.new(ok: true, placed: result.value, skipped: 0)
      else
        Result.new(ok: false, error: result.error.presence || "Could not add that photo.")
      end
    end

    def default_library
      root = @images_recording.root_recording
      return unless root.respond_to?(:image_library)

      key = RecordingStudioPresskits.configuration.library_key_for(@images_recording.recordable_type)
      root.image_library(key: key, actor: @actor)
    end

    def missing_parent
      Result.new(ok: false, error: "An images section is required.")
    end

    def already_in_section
      Result.new(ok: false, error: "That photo is already in this section.")
    end
  end
end
