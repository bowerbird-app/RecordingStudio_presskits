# frozen_string_literal: true

require "stringio"
require "recording_studio_presskits/podcast_artwork/remote"
require "recording_studio_presskits/podcast_artwork/live"

module RecordingStudioPresskits
  class PodcastArtwork
    Image = Struct.new(:bytes, :content_type, :filename, :title, :show_name, keyword_init: true)

    class << self
      # A test client. Production leaves this unset and uses the live fetcher.
      attr_accessor :http

      def store!(recording, actor:)
        new(recording, actor).store!
      end

      def image_url(recording, helpers:)
        uploaded = uploaded_url(recording, helpers)
        return uploaded if uploaded.present?

        file = recording&.recordable&.try(:fetched_artwork)
        return unless file&.attached?

        helpers.main_app.url_for(file)
      rescue StandardError
        nil
      end

      def uploaded?(recording)
        DirectImages.list(recording).any?
      end

      # Attach on the unsaved snapshot inside revise. A saved recordable is
      # immutable, so ActiveStorage cannot attach after that save.
      def carry!(row, previous)
        return unless previous.respond_to?(:fetched_artwork) && previous.fetched_artwork.attached?
        return if row.fetched_artwork.attached?

        row.fetched_artwork.attach(previous.fetched_artwork.blob)
      rescue StandardError
        nil
      end

      private

      def uploaded_url(recording, helpers)
        item = DirectImages.list(recording).first
        return if item.blank?

        DirectImages.url_for(item, helpers: helpers)
      end
    end

    def initialize(recording, actor)
      @recording = recording
      @actor = actor
    end

    def store!
      return if skip_fetch?

      image = Remote.image_for(podcast.url, http: client)
      remember!(image) if image
    rescue StandardError
      nil
    end

    private

    attr_reader :recording, :actor

    def skip_fetch?
      podcast.blank? || self.class.uploaded?(recording) || fresh?
    end

    def fresh?
      podcast.artwork_source_url == podcast.url && podcast.fetched_artwork.attached?
    end

    def remember!(image)
      blob = upload_blob(image)
      root.revise(recording, actor: actor) do |row|
        row.assign_attributes(artwork_changes(image))
        row.fetched_artwork.attach(blob)
      end
    end

    def artwork_changes(image)
      {
        title: filled(podcast.title, image.title),
        show_name: filled(podcast.show_name, image.show_name),
        artwork_source_url: podcast.url
      }
    end

    def filled(current, incoming)
      return current if current.present?

      incoming.to_s.strip.first(200).presence
    end

    def upload_blob(image)
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(image.bytes),
        filename: image.filename,
        content_type: image.content_type
      )
    end

    def client
      self.class.http || Live.method(:call)
    end

    def podcast
      recording&.recordable if recording&.recordable.is_a?(Podcast)
    end

    def root
      recording.root_recording
    end
  end
end
