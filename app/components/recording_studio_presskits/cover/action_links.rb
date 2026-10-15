# frozen_string_literal: true

module RecordingStudioPresskits
  module Cover
    # Destinations for the gem's default cover buttons. Cover itself only
    # renders the slots a caller fills.
    class ActionLinks
      PRESS_ROLE = /\Apress contacts?\z/i
      CONTACT_TITLE = /\A(press )?contacts?\z/i

      def initialize(recording:, helpers:)
        @recording = recording
        @helpers = helpers
      end

      def download_href
        package_path.presence || assets_anchor
      end

      def contact_href
        press_contact_url.presence || contact_section_anchor
      end

      def actor
        return @helpers.current_user if @helpers.respond_to?(:current_user, true)

        current_actor
      end

      private

      def current_actor
        return unless defined?(Current)
        return unless Current.respond_to?(:actor)

        Current.actor
      end

      def package_path
        return unless @helpers.respond_to?(:recording_studio_downloadable)

        @helpers.recording_studio_downloadable.recording_package_path(@recording)
      rescue StandardError
        nil
      end

      def assets_anchor
        slug = heading_slug(image_sections.first)
        "##{slug}" if slug
      end

      def image_sections
        @image_sections ||= sections.select { |section| image_section?(section) }
      end

      def image_section?(section)
        content = KitQuery.section_content(section)
        content&.recordable.is_a?(Images) && DirectImages.list(content).any?
      end

      def press_contact_url
        credit_lines.each do |line|
          next unless line.recordable.role.to_s.strip.match?(PRESS_ROLE)

          url = credit_url(line)
          return url if url.present?
        end
        nil
      end

      def credit_lines
        sections.flat_map { |section| lines_for(section) }
      end

      def lines_for(section)
        content = KitQuery.section_content(section)
        return [] unless content&.recordable.is_a?(CreditsSection)

        Credits.visible_lines(content)
      end

      def credit_url(line)
        credit = Credits.credit_for(line)
        return unless Credits.shown_credit?(credit)

        normalize_url(credit.recordable.url.to_s.strip)
      end

      def normalize_url(raw)
        return if raw.blank?
        return raw if raw.match?(/\Amailto:/i)
        return "mailto:#{raw}" if email?(raw)

        FlatPack::AttributeSanitizer.sanitize_url(raw)
      end

      def email?(raw)
        raw.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
      end

      def contact_section_anchor
        sections.each do |section|
          slug = contact_slug(section)
          return "##{slug}" if slug
        end
        nil
      end

      def contact_slug(section)
        title = RecordingStudioPresskits.section_heading(section).to_s.strip
        return unless title.match?(CONTACT_TITLE)

        RecordingStudioPresskits.section_anchor_id(section)
      end

      def heading_slug(section)
        return if section.blank?

        RecordingStudioPresskits.section_anchor_id(section)
      end

      def sections
        @sections ||= @recording.blank? ? [] : KitQuery.sections_for(@recording)
      end
    end
  end
end
