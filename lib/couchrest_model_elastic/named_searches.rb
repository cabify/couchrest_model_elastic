module CouchrestModelElastic
  class NamedSearches
    include Enumerable

    def self.extend_with_named_searches(object, named_searches, helper_method_name = :named_searches)
      # Mixin an anonymous module into object which creates a helper method and search methods equal to the named_searches
      object.extend(Module.new do
        define_method(helper_method_name) { named_searches }
        named_searches.each do |search_name|
          define_method(search_name) { |*args| self.send(helper_method_name).call(search_name, *args) }
        end
      end)
    end

    attr_reader :client
    attr_accessor :index, :type, :result_source_mapper

    StoredQuery = Struct.new(:search_args, :query)

    def initialize(&config)
      @client = Client.new
      self.index = '_all'
      self.type = nil
      @query_store = {}
      self.tap(&config) if config
    end

    def named_search(name, *query_args, &query_builder)
      @query_store[name.intern] = StoredQuery.new(query_args, query_builder)
    end

    def [](search_name)
      @query_store.fetch(search_name.intern)
    end

    def each(&block)
      @query_store.keys.each(&block)
    end

    def call(search_name, *args)
      stored_query = self[search_name]
      query_builder = stored_query.query ? Proc.new { |query| stored_query.query.call(query, *args) } : nil
      self.search(*stored_query.search_args, &query_builder)
    end

    def search(search_args = {}, &query_builder)
      args = {index: self.index, type: self.type, result_mapper: self.result_source_mapper}.merge(search_args)
      self.client.search(args.delete(:index), args, &query_builder)
    end
  end
end