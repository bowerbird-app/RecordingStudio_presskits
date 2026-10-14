# frozen_string_literal: true

module RecordingStudioPresskits
  class KitDownload
    class TextFile # rubocop:disable Metrics/ClassLength
      def self.call(recording)
        new(recording).to_s
      end

      def initialize(recording)
        @recording = recording
        @kit = recording&.recordable
      end

      def to_s
        return "" if @kit.blank?

        "#{[header.join("\n"), *section_blocks].compact_blank.join("\n\n").strip}\n"
      end

      CONTENT_HANDLERS = {
        "RecordingStudioPresskits::Text" => :text_lines,
        "RecordingStudioPresskits::Images" => :image_section_lines,
        "RecordingStudioPresskits::QuoteSection" => :quote_lines,
        "RecordingStudioPresskits::StatsSection" => :stat_lines,
        "RecordingStudioPresskits::CreditsSection" => :credit_lines,
        "RecordingStudioPresskits::VideoSection" => :video_lines,
        "RecordingStudioPresskits::PodcastSection" => :podcast_lines,
        "RecordingStudioPresskits::LocationSection" => :location_section_lines,
        "RecordingStudioPresskits::Files" => :file_section_lines
      }.freeze

      private

      def header
        [
          @kit.title.to_s.strip.presence,
          @kit.description.to_s.strip.presence,
          labeled(:company, company_name),
          labeled(:location, location_name),
          labeled(:date, published_on)
        ].compact
      end

      def section_blocks
        cover_block + visible_sections.flat_map { |section| section_block(section) }
      end

      def cover_block
        item = CoverImage.resolved(@recording)
        return [] if item.blank?

        [([t("cover")] + image_lines(item)).join("\n")]
      end

      def visible_sections
        KitQuery.sections_for(@recording).select do |section|
          PressKits::SectionFrameComponent.new(section_recording: section).content_visible?
        end
      end

      def section_block(section)
        content = KitQuery.section_content(section)
        lines = [
          RecordingStudioPresskits.section_heading(section),
          section.recordable.subtitle.to_s.strip.presence,
          *content_lines(content)
        ].compact
        return [] if lines.empty?

        [lines.join("\n")]
      end

      def content_lines(content)
        recordable = content&.recordable
        handler = content_handler_for(recordable)
        handler ? send(handler, content, recordable) : []
      end

      def content_handler_for(recordable)
        CONTENT_HANDLERS[recordable.class.name]
      end

      def text_lines(_content, recordable)
        [plain_text(recordable.body)].compact_blank
      end

      def image_section_lines(content, _recordable)
        DirectImages.list(content).flat_map { |item| image_lines(item) }
      end

      def image_lines(item)
        attachment = item&.recordable
        return [] if attachment.blank?

        [
          labeled(:photo, attachment.try(:original_filename).presence || attachment.try(:name)),
          labeled(:caption, attachment.try(:caption)),
          labeled(:credit, attachment.try(:credit)),
          labeled(:alt, DirectImages.alt_for(item))
        ].compact
      end

      def quote_lines(content, _recordable)
        QuoteSection::Component.new(recording: content).quotes.filter_map do |child|
          quoted_block(child.recordable)
        end
      end

      def quoted_block(quote)
        body = quote.body.to_s.strip.presence
        return if body.blank?

        cite = [quote.name, quote.role, quote.organisation].filter_map { |value| value.to_s.strip.presence }
        [body, cite.any? ? "— #{cite.join(', ')}" : nil].compact.join("\n")
      end

      def stat_lines(content, _recordable)
        StatsSection.active_stats(content).filter_map { |child| stat_block(child.recordable) }
      end

      def stat_block(stat)
        value = stat.formatted_value.to_s.strip.presence
        return if stat.label.blank? || value.blank?

        [labeled(:stat, "#{stat.label}: #{value}"), stat.description.to_s.strip.presence].compact.join("\n")
      end

      def credit_lines(content, _recordable)
        Credits.visible_lines(content).filter_map { |line| credit_block(line) }
      end

      def credit_block(line)
        credit = Credits.credit_for(line)&.recordable
        return if credit.blank?

        role = line.recordable.role.to_s.strip.presence
        name = credit.name.to_s.strip.presence
        return if name.blank?

        [role, name].compact.join(" — ")
      end

      def video_lines(content, _recordable)
        VideoSection.active_videos(content).filter_map { |child| video_block(child.recordable) }
      end

      def podcast_lines(content, _recordable)
        PodcastSection.active_podcasts(content).filter_map { |child| podcast_block(child.recordable) }
      end

      def podcast_block(podcast)
        lines = [podcast.show_name, podcast.title, podcast.meta_line, podcast.url].filter_map do |value|
          value.to_s.strip.presence
        end
        lines.join("\n").presence
      end

      def file_section_lines(content, _recordable)
        DirectFiles.list(content).filter_map { |item| file_block(item.recordable) }
      end

      def file_block(attachment)
        return if attachment.blank?

        name = file_name(attachment)
        return if name.blank?

        [name, file_meta(attachment), file_description(attachment)].compact.join("\n")
      end

      def file_name(attachment)
        attachment.name.to_s.strip.presence || attachment.original_filename.to_s.strip.presence
      end

      def file_description(attachment)
        attachment.description.to_s.strip.presence
      end

      def file_meta(attachment)
        [attachment.original_filename.to_s.strip.presence, file_size(attachment)].compact.join(" · ").presence
      end

      def file_size(attachment)
        bytes = attachment.byte_size
        return if bytes.nil?

        ActiveSupport::NumberHelper.number_to_human_size(bytes, strip_insignificant_zeros: true)
      end

      def location_section_lines(content, _recordable)
        LocationSection.active_locations(content).filter_map { |child| location_block(child.recordable) }
      end

      def location_block(location)
        return if location.blank?

        if location.respond_to?(:display_name)
          location.display_name.to_s.strip.presence
        else
          [location.try(:title), location.try(:locality)]
            .filter_map { |part| part.to_s.strip.presence }
            .join(", ")
            .presence
        end
      end

      def video_block(video)
        title = video.try(:title).to_s.strip.presence
        url = video.try(:url).to_s.strip.presence
        return if title.blank? && url.blank?

        [title, video_meta(video), url].compact.join("\n")
      end

      def video_meta(video)
        provider = video.try(:provider_name).to_s.strip.presence
        length = video.try(:duration_label).to_s.strip.presence
        [provider, length].compact.join(" · ").presence
      end

      def company_name
        Cover::Company.name_for(@recording).to_s.strip.presence
      end

      def location_name
        location = KitLocation.recordable_for(@recording)
        return if location.blank?

        if location.respond_to?(:display_name)
          location.display_name.to_s.strip.presence
        else
          [location.try(:title), location.try(:locality)]
            .filter_map { |part| part.to_s.strip.presence }
            .join(", ")
            .presence
        end
      end

      def published_on
        publishable = @recording.try(:current_publishable)
        stamp = publishable.try(:publish_at).presence || publishable.try(:created_at)
        return if stamp.blank?

        I18n.l(stamp.to_date, format: :long)
      end

      def labeled(key, value)
        text = value.to_s.strip.presence
        return if text.blank?

        "#{t(key)}: #{text}"
      end

      def plain_text(html)
        Loofah.fragment(html.to_s).to_text.gsub(/\r\n?/, "\n").gsub(/\n{3,}/, "\n\n").strip.presence
      end

      def t(key)
        I18n.t("recording_studio_presskits.download.text.#{key}")
      end
    end
  end
end
