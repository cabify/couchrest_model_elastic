module CouchrestModelElastic
  class SearchResults
    include Enumerable

    attr_reader :meta_data, :max_score, :total

    Result = Struct.new(:source, :index, :type, :id, :score, :highlight) do
      def self.create_from_hit(hit, mapper)
        self.new(mapper.call(hit['_source']), hit['_index'], hit['_type'], hit['_id'], hit['_score'], hit['highlight'])
      end

      def highlight
        self[:highlight] || {}
      end
    end

    def initialize(raw_search_result, &source_mapper)
      hits = raw_search_result.delete('hits') || {}
      @hits = hits['hits'] || []
      @meta_data = raw_search_result
      @max_score = hits['max_score']
      @total = hits['total'] || 0
      @source_mapper = source_mapper || ->(source) { source }
    end

    def each(&block)
      results.each(&block)
    end

    def [](index)
      results[index]
    end

    def results
      @results ||= @hits.map do |hit|
        Result.create_from_hit(hit, @source_mapper)
      end
    end
  end
end