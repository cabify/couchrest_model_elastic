module CouchrestModelElastic
  module CouchModelSearchable

    RESULT_MAPPER = ->(source) { CouchRest::Model::Base.build_from_database(source) }

    def searchable(&config)
      @search_config = SearchConfig.setup(self, &config)
    end

    class SearchConfig
      attr_reader :design_mapper, :model, :couchdb_database_config, :couchdb_database_name, :model_name, :search_index, :search_type

      class SetupCallbacks
        def initialize
          @callbacks = []
          @run = true
        end

        def add(&clbk)
          @callbacks << clbk
        end

        def run?
          @run && @callbacks.present?
        end

        def run=(bool)
          @run = bool
        end

        def run!
          count = 0
          @callbacks.each { |clbk| clbk.call; count += 1 }.clear if run?
          count
        end
      end

      def self.setup_callbacks
        @setup_callbacks ||= SetupCallbacks.new
      end

      def self.run_setup_callbacks
        callback_count = 0
        if @run_setup_callbacks && @setup_callbacks && (callback_count = @setup_callbacks.size) > 0
          @setup_callbacks.each { |clbk| clbk.call }.clear
        end
        callback_count
      end

      def self.cancel_setup_callbacks
        @run_setup_callbacks = false
      end

      def self.setup(*args, &config)
        self.new(*args).tap do |search_config|
          config.call(search_config) if config
          search_config.send(:setup)
        end
      end

      def initialize(design_mapper)
        @design_mapper = design_mapper
        @model = design_mapper.model
        @model_name = @model.to_s

        @couchdb_database_config = design_mapper.model.send(:connection_configuration)
        # This is a bit of a hack since model.database.name would instantiate the server connection, which would fail
        @couchdb_database_name = [@couchdb_database_config[:prefix], @couchdb_database_config[:suffix]].reject { |s| s.to_s.empty? }.join(@couchdb_database_config[:join])

        # The Elasticsearch index under which to import
        @search_index = @couchdb_database_name
        # The Elasticsearch type under which to import
        @search_type = self.prefixed_name(@model_name)
        @filter_name = nil
      end

      def set_filter(filter_name, body)
        @filter_name = prefix_filter_name(filter_name)
        filter_fnc = %{function(doc, req){ #{body} }}
        self.design_mapper.filter(@filter_name, filter_fnc)
        river_config.couch_filter = "#{self.design_mapper.design_doc.id.split('/').last}/#{@filter_name}"
      end

      def named_search(*args, &query)
        self.named_searches.named_search(*args, &query)
      end

      def named_count(*args, &query)
        self.named_searches.named_count(*args, &query)
      end

      def named_searches
        @named_searches ||= NamedSearches.new { |ns|
          ns.index = self.search_index
          ns.type = self.search_type
          ns.result_source_mapper = RESULT_MAPPER
        }
      end

      def river_config
        @river_config ||= CouchrestModelElastic::River.new_with_defaults(self.river_config_index_type,
          couch_db: self.couchdb_database_name,
          couch_host: self.couchdb_database_config[:host],
          couch_port: self.couchdb_database_config[:port],
          couch_user: self.couchdb_database_config[:username],
          couch_password: self.couchdb_database_config[:password],
          index: self.search_index,
          type: self.search_type
        )
      end

      protected

      def setup
        default_filter! unless filter_set?
        NamedSearches.extend_with_named_searches(self.model, self.named_searches)
        self.class.setup_callbacks.add { setup_river }
      end

      def setup_river
        self.river_config.update
      end

      def filter_set?
        !@filter_name.nil?
      end

      def default_filter!
        # Deleted documents only have doc._id, doc._rev, and doc._deleted
        set_filter(:default, "return doc._deleted || doc['#{self.model.model_type_key}'] == '#{self.model_name}';")
      end

      def river_config_index_type
        # Unique Elasticsearch type for each river configuration
        self.prefixed_name(self.couchdb_database_name, self.model_name)
      end

      # Helper to create a prefixed name given string *components
      def prefixed_name(*components)
        [*components, self.design_mapper.prefix].compact.join('-')
      end

      def prefix_filter_name(name)
        ['couchrest_model_elastic', name].join('-')
      end
    end

    module DesignSyncCallbacksExtension
      # Design#sync is only called in Development
      # See rake task for running callbacks in Production or when auto_update_design_doc == false
      def self.included(design)
        design.send(:alias_method, :sync_without_callbacks!, :sync!)
        design.send(:alias_method, :sync!, :sync_with_callbacks!)
      end

      def sync_with_callbacks!(*args, &blk)
        sync_without_callbacks!(*args, &blk).tap do
          CouchrestModelElastic::CouchModelSearchable::SearchConfig.setup_callbacks.run!
        end
      end
    end
  end
end

require 'couchrest'
require 'couchrest/model/design'
require 'couchrest/model/designs/design_mapper'
CouchRest::Model::Designs::DesignMapper.send(:include, CouchrestModelElastic::CouchModelSearchable)
CouchRest::Model::Design.send(:include, CouchrestModelElastic::CouchModelSearchable::DesignSyncCallbacksExtension)