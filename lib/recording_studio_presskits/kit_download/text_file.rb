# frozen_string_literal: true

module RecordingStudioPresskits
  class KitDownload
    class TextFile
      def self.call(recording)
        new(recording).to_s
      end

      def initialize(recording)
        @recording = recording
        @kit = recording&.recordable
      end

      def to_s
        return "" if @kit.blank?

        [header.join("\n"), *section_blocks].compact_blank.join("\n\n").strip + "\n"
      end

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
        case recordable
        when Text
          [plain_text(recordable.body)].compact_blank
        when Images
          LibraryImages.resolve(content).flat_map { |item| image_lines(item) }
        when QuoteSection
          quote_lines(content)
        when FactsSection
          fact_lines(content)
        when CreditsSection
          credit_lines(content)
        when VideoSection
          video_lines(content)
        else
          []
        end
      end

      def image_lines(item)
        attachment = item&.attachment
        return [] if attachment.blank?

        [
          labeled(:photo, attachment.try(:original_filename).presence || attachment.try(:name)),
          labeled(:caption, attachment.try(:caption)),
          labeled(:credit, attachment.try(:credit)),
          labeled(:alt, LibraryImages.alt_for(item))
        ].compact
      end

      def quote_lines(content)
        QuoteSection::Component.new(recording: content).quotes.filter_map do |child|
          quote = child.recordable
          body = quote.body.to_s.strip.presence
          next if body.blank?

          cite = [quote.name, quote.role, quote.organisation].filter_map { |value| value.to_s.strip.presence }
          [body, cite.any? ? "— #{cite.join(', ')}" : nil].compact.join("\n")
        end
      end

      def fact_lines(content)
        FactsSection.active_facts(content).filter_map do |child|
          fact = child.recordable
          value = fact.formatted_value.to_s.strip.presence
          next if fact.label.blank? || value.blank?

          [labeled(:fact, "#{fact.label}: #{value}"), fact.description.to_s.strip.presence].compact.join("\n")
        end
      end

      def credit_lines(content)
        Credits.visible_lines(content).filter_map do |line|
          credit = Credits.credit_for(line)&.recordable
          next if credit.blank?

          role = line.recordable.role.to_s.strip.presence
          name = credit.name.to_s.strip.presence
          next if name.blank?

          [role, name].compact.join(" — ")
        end
      end

      def video_lines(content)
        VideoSection.active_videos(content).filter_map do |child|
          video = child.recordable
          title = video.try(:title).to_s.strip.presence
          url = video.try(:url).to_s.strip.presence
          next if title.blank? && url.blank?

          [title, url].compact.join("\n")
        end
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
