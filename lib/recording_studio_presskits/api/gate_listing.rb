# frozen_string_literal: true

module RecordingStudioPresskits
  module Api
    module Gate
      module_function

      PAGE_KEYS = %i[limit pagination_token sort order count].freeze

      def search_title(relation, context)
        query = param(context, :q).to_s.strip
        return relation if query.blank?

        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
        relation.joins(press_kit_join_sql).where(PressKit.arel_table[:title].matches(pattern))
      end

      def page(context, relation)
        pagination = paginate(context, relation)
        raise ::RecordingStudioApi::InvalidPaginationTokenError, pagination.error if pagination.failure?

        { json: page_json(context, pagination) }
      end

      def serialize(context, recording)
        ::RecordingStudioApi::Serializers::ResourceRecordingSerializer.call(
          recording,
          version: context.api_version,
          api: context.api_key,
          context: context
        )
      end

      def deleted(context, recording)
        { json: serialize(context, recording).merge(deleted: true, deleted_via: "trashed") }
      end

      def paginate(context, relation)
        ::RecordingStudioApi::Services::PaginateResourceCollection.call(**page_options(context, relation))
      end

      def page_options(context, relation)
        PAGE_KEYS.index_with { |key| param(context, key) }.merge(page_scope(context, relation))
      end

      def page_scope(context, relation)
        {
          relation: relation,
          resource: context.resource_name,
          recordable_type: context.recordable_type,
          api: context.api_key,
          scope_key: "client:#{context.api_client&.id}"
        }
      end

      def page_json(context, pagination)
        pagination.value.response_body { |recordings, meta| page_body(context, recordings, meta) }
      end

      def page_body(context, recordings, meta)
        {
          resource: context.resource_name,
          type: context.recordable_type.demodulize,
          records: recordings.map { |recording| serialize(context, recording) },
          meta: meta
        }
      end

      def press_kit_join_sql
        recordings = RecordingStudio::Recording.table_name
        kits = PressKit.table_name
        <<~SQL.squish
          INNER JOIN #{kits}
            ON #{kits}.id = #{recordings}.recordable_id
           AND #{recordings}.recordable_type = #{RecordingStudio::Recording.connection.quote(PressKit.name)}
        SQL
      end
      private_class_method :paginate, :page_options, :page_scope, :page_json, :page_body, :press_kit_join_sql
    end
  end
end
