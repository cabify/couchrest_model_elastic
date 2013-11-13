require 'uri'

module CouchrestModelElastic
  module CouchModelSearchable

    RESULT_MAPPER = ->(source) { CouchRest::Model::Base.build_from_database(source) }

    def searchable(&config)
      @search_config = SearchConfig.setup(self, &config)
    end

    class SearchConfig
      attr_reader :design_mapper, :model, :search_index, :search_type

      def self.setup(*args, &config)
        self.new(*args).tap do |search_config|
          config.call(search_config) if config
          search_config.send(:setup)
        end
      end

      def initialize(design_mapper)
        @design_mapper = design_mapper
        @model = design_mapper.model
        @search_index = self.model.database.name
        @search_type = self.prefixed_name(self.model.to_s)
        @filter_name = nil
      end

      def set_filter(filter_name, body)
        @filter_name = filter_name
        filter_fnc = %{function(doc, req){ #{body} }}
        self.design_mapper.filter(filter_name, filter_fnc)
        river_config.couch_filter = "#{self.design_mapper.design_doc.id.split('/').last}/#{filter_name}"
      end

      def named_search(*args, &query)
        self.named_searches.named_search(*args, &query)
      end

      def named_searches
        @named_searches ||= NamedSearches.new.tap { |ns|
          ns.index = self.search_index
          ns.type = self.search_type
          ns.result_source_mapper = RESULT_MAPPER
        }
      end

      def river_config
        @river_config ||= CouchrestModelElastic::River.new_with_defaults(river_config_index_type,
          couch_db:     self.model.database.name,
          couch_host:   self.model_database_uri.host,
          couch_port:   self.model_database_uri.port,
          index:        self.search_index,
          type:         self.search_type
        )
      end

      protected

      def setup
        default_filter! unless filter_set?
        NamedSearches.extend_with_named_searches(self.model, self.named_searches)
        self.design_mapper.design_doc.add_sync_callback { |_| setup_river }
      end

      def setup_river
        self.river_config.update
      end

      def filter_set?
        !@filter_name.nil?
      end

      def default_filter!
        set_filter(:search_default, "return doc['#{self.model.model_type_key}'] == '#{self.model.to_s}';")
      end

      def river_config_index_type
        self.prefixed_name(self.model.database.name, self.model.to_s)
      end

      # Helper to create a prefixed name given string *components
      def prefixed_name(*components)
        [*components, self.design_mapper.prefix].compact.join('-')
      end

      def model_database_uri
        @model_database_uri ||= URI.parse(self.model.database.host)
      end
    end

    module DesignSyncCallbacksExtension
      def self.included(design)
        design.send(:alias_method, :sync_without_callbacks!, :sync!)
        design.send(:alias_method, :sync!, :sync_with_callbacks!)
      end

      def add_sync_callback(&clbk)
        (@sync_callbacks ||= []) << clbk
      end

      def sync_with_callbacks!(*args, &blk)
        sync_without_callbacks!(*args, &blk).tap {
          @sync_callbacks.each { |clbk| clbk.call(self) } if @sync_callbacks
        }
      end
    end
  end
end

require 'couchrest'
require 'couchrest/model/design'
require 'couchrest/model/designs/design_mapper'
CouchRest::Model::Designs::DesignMapper.send(:include, CouchrestModelElastic::CouchModelSearchable)
CouchRest::Model::Design.send(:include, CouchrestModelElastic::CouchModelSearchable::DesignSyncCallbacksExtension)