# frozen_string_literal: true

module RecordingStudioPresskits
  class Podcast < ApplicationRecord
    self.table_name = "recording_studio_podcasts"

    HTTP_URL = %r{\Ahttps?://[^\s]+\z}i

    recording_studio_recordable label: "Podcast",
                                root: false,
                                allowed_parent_types: ["RecordingStudioPresskits::PodcastSection"]

    include RecordingStudio::Capabilities::Trashable.to
    include RecordingStudio::Capabilities::Attachable.to(
      allowed_content_types: ["image/*"],
      enabled_attachment_kinds: [:image],
      max_file_size: 10.megabytes,
      max_file_count: 1,
      auth_roles: { remove: :edit }
    )

    # Fetched artwork is a stored copy on this snapshot, not a second upload.
    # The one Attachable image stays free for a cover someone chose.
    has_one_attached :fetched_artwork

    validates :url, presence: true, format: {
      with: HTTP_URL,
      message: "needs to start with http:// or https://"
    }
    validates :title, :show_name, length: { maximum: 200 }, allow_nil: true
    validates :duration, length: { maximum: 40 }, allow_nil: true

    before_validation :clear_blanks

    def episode_title
      title.to_s.strip.presence || "Podcast"
    end

    def meta_line
      [aired_label, duration.to_s.strip.presence].compact.join(" · ").presence
    end

    def aired_label
      return if aired_on.blank?

      I18n.l(aired_on, format: :long)
    end

    def embed
      PodcastEmbed.for(url)
    end

    private

    def clear_blanks
      self.url = url.to_s.strip
      self.title = blank_to_nil(title)
      self.show_name = blank_to_nil(show_name)
      self.duration = blank_to_nil(duration)
      self.artwork_source_url = blank_to_nil(artwork_source_url)
    end

    def blank_to_nil(value)
      value.to_s.strip.presence
    end
  end
end
