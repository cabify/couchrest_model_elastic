module CouchrestModelElastic
  class NamedSearches
    include Enumerable

    def self.extend_with_named_searches(object, named_searches, helper_method_name = :named_searches)
      object.extend(Module.new do
        define_method(helper_method_name) { named_searches }
        named_searches.each do |search_name|
          define_method(search_name) { |*args| self.send(helper_method_name).call(search_name, *args) }
        end
      end)
    end

    attr_reader :client, :index, :type

    def initialize(&config)
      @client = Client.new
      @index = '_all'
      @type = nil
      @named_searches = {}
      self.tap(&config) if config
    end

    def result_source_mapper=(mapper)
      @result_source_mapper = mapper
    end

    def index=(i)
      @index = i
    end

    def type=(t)
      @type = t
    end

    def named_search(name, &query)
      @named_searches[name.intern] = query
    end

    def call(search_name, *args)
      named_search = @named_searches.fetch(search_name.intern)
      # TODO: add argument arity checking
      self.search { |query| named_search.call(query, *args) }
    end

    def search(mapper = self.result_source_mapper, &query_builder)
      self.client.search(self.index, self.type, mapper, &query_builder)
    end

    def each(&block)
      @named_searches.keys.each(&block)
    end

    protected

    def result_source_mapper
      @result_source_mapper ||= ->(source) { source }
    end
  end
end