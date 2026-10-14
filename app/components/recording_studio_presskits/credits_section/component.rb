# frozen_string_literal: true

module RecordingStudioPresskits
  class CreditsSection
    class Component < ViewComponent::Base
      def initialize(recording:)
        super()
        @recording = recording
      end

      def render?
        lines.any?
      end

      def lines
        Credits.visible_lines(@recording)
      end

      def credit_for(line)
        Credits.credit_for(line)&.recordable
      end

      def credit_url(credit)
        FlatPack::AttributeSanitizer.sanitize_url(credit&.url)
      end

      def icon_name(line)
        CreditIcons.normalize(line.recordable.icon)
      end

      # When one credit has an icon, the others keep a matching gap so names line up.
      def reserve_icon_space?
        lines.any? { |line| icon_name(line).present? }
      end

      def copy_text
        lines.filter_map { |line| copy_line(line) }.join("\n")
      end

      def copy_button
        text = copy_text
        return if text.blank?

        FlatPack::CopyButton::Component.new(
          text: text,
          label: "Copy credits",
          style: :default,
          size: :sm
        )
      end

      private

      def copy_line(line)
        credit = credit_for(line)
        return if credit.blank?

        name = credit.name.to_s.strip
        return if name.blank?

        role = line.recordable.role.to_s.strip
        role.present? ? "#{role}: #{name}" : name
      end
    end
  end
end
