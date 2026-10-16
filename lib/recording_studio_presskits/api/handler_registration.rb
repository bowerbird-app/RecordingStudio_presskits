# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module HandlerRegistration
      READ_TYPES = %w[
        RecordingStudioPresskits::PressKit
        RecordingStudioPresskits::KitSection
        RecordingStudioPresskits::Text
        RecordingStudioPresskits::Quote
        RecordingStudioPresskits::QuoteSection
        RecordingStudioPresskits::Stat
        RecordingStudioPresskits::StatsSection
        RecordingStudioPresskits::Credit
        RecordingStudioPresskits::CreditLine
        RecordingStudioPresskits::CreditsSection
        RecordingStudioPresskits::ListItem
        RecordingStudioPresskits::ListSection
        RecordingStudioPresskits::Podcast
        RecordingStudioPresskits::PodcastSection
        RecordingStudioPresskits::VideoSection
        RecordingStudioPresskits::LocationSection
        RecordingStudioPresskits::Images
        RecordingStudioPresskits::Files
        RecordingStudioPresskits::MenuSection
      ].freeze

      CREATE_TYPES = %w[
        RecordingStudioPresskits::PressKit
        RecordingStudioPresskits::Quote
        RecordingStudioPresskits::Stat
        RecordingStudioPresskits::ListItem
        RecordingStudioPresskits::Podcast
      ].freeze

      UPDATE_TYPES = %w[
        RecordingStudioPresskits::PressKit
        RecordingStudioPresskits::KitSection
        RecordingStudioPresskits::Text
        RecordingStudioPresskits::Quote
        RecordingStudioPresskits::Stat
        RecordingStudioPresskits::Credit
        RecordingStudioPresskits::CreditLine
        RecordingStudioPresskits::ListItem
        RecordingStudioPresskits::Podcast
        RecordingStudioPresskits::MenuSection
      ].freeze

      DESTROY_TYPES = %w[
        RecordingStudioPresskits::PressKit
        RecordingStudioPresskits::KitSection
        RecordingStudioPresskits::Text
        RecordingStudioPresskits::Quote
        RecordingStudioPresskits::Stat
        RecordingStudioPresskits::Credit
        RecordingStudioPresskits::CreditLine
        RecordingStudioPresskits::ListItem
        RecordingStudioPresskits::Podcast
      ].freeze

      def register_resource_handlers!
        return unless ::RecordingStudioApi.respond_to?(:register_resource_handler)

        READ_TYPES.each do |type_name|
          register_handler(type_name, :index, ResourceIo::Index)
          register_handler(type_name, :show, ResourceIo::Show)
        end
        CREATE_TYPES.each { |type_name| register_handler(type_name, :create, ResourceIo::Create) }
        register_handler("RecordingStudioPresskits::Credit", :create, CreditCreate)
        register_handler("RecordingStudioPresskits::CreditLine", :create, CreditLineCreate)
        UPDATE_TYPES.each { |type_name| register_handler(type_name, :update, ResourceIo::Update) }
        DESTROY_TYPES.each { |type_name| register_handler(type_name, :destroy, ResourceIo::Destroy) }
      end

      def register_handler(type_name, action, handler)
        return if ::RecordingStudioApi.resource_handler(type_name, action)

        ::RecordingStudioApi.register_resource_handler(type_name, action, handler: handler)
      end
    end
  end
end
