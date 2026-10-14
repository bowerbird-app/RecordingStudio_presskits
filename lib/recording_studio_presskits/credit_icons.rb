# frozen_string_literal: true

module RecordingStudioPresskits
  # Icons an editor can put on a credit line. The list is curated.
  # A blank choice stays blank. Nothing here is guessed from the role.
  module CreditIcons
    CHOICES = {
      "building-office-2" => "Architecture",
      "swatch" => "Design",
      "camera" => "Photography",
      "paint-brush" => "Styling",
      "cube" => "Furniture",
      "user" => "Person",
      "pencil" => "Writing",
      "musical-note" => "Music"
    }.freeze

    class << self
      def options
        [["No icon", ""]].concat(CHOICES.map { |name, label| [label, name] })
      end

      def normalize(name)
        value = name.to_s.strip
        return if value.blank?
        return value if CHOICES.key?(value)

        nil
      end
    end
  end
end
