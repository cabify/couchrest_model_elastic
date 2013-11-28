module CouchrestModelElastic
  class SearchResults
    include Enumerable

    attr_reader :meta_data, :max_score, :total, :facets

    Result = Struct.new(:source, :index, :type, :id, :score, :highlight) do
      def self.create_from_hit(hit, mapper = nil)
	source = mapper ? mapper.call(hit['_source']) : hit['_source']
	self.new(source, hit['_index'], hit['_type'], hit['_id'], hit['_score'], hit['highlight'])
      end

      def highlight
        self[:highlight] || {}
      end
    end

    class Facet
      include Enumerable

      attr_reader :terms, :name, :type, :meta_data
      def initialize(name, raw_facet_result)
	@name = name
	@terms = raw_facet_result.delete('terms')
	@type = raw_facet_result.delete('_type')
	@meta_data = raw_facet_result
      end

      def each(&block)
	self.terms.each(&block)
      end
    end

    def initialize(raw_search_result, &source_mapper)
      hits = raw_search_result.delete('hits') || {}
      @hits = hits['hits'] || []
      @facets = (raw_search_result.delete('facets') || {}).each_with_object({}) { |(facet_name, facet), h| h[facet_name.to_sym] = Facet.new(facet_name.to_sym, facet) }
      @meta_data = raw_search_result
      @max_score = hits['max_score']
      @total = hits['total'] || 0
      @source_mapper = source_mapper
    end

    def each(&block)
      results.each(&block)
    end

    def [](index)
      results[index]
    end

    def results
      @results ||= @hits.map { |hit| Result.create_from_hit(hit, @source_mapper) }
    end
  end
end