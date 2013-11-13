require 'elasticsearch'
require 'jbuilder'

module CouchrestModelElastic
  class Client
    attr_reader :client

    def initialize(opts = {})
      @client = Elasticsearch::Client.new(Config.to_h.merge(opts))
    end

    def search(index, type = nil, result_source_mapper = nil, body = nil, &query_builder)
      result_source_mapper ||= ->(source) { source }
      args = {index: index}
      args[:type] = type if type
      args[:body] = body if body
      SearchResults.new(perform(:search, args, &query_builder), &result_source_mapper)
    end

    def index(index, type, id, body = nil, &query_builder)
      perform(:index, index: index, type: type, id: id, body: body, &query_builder)
    end

    def create(index, type, id, body = nil, &query_builder)
      perform(:create, index: index, type: type, id: id, body: body, &query_builder)
    end

    protected

    def perform(action, arguments = {}, &query_builder)
      raise ArgumentError, ':body cannot be set if passed a builder block' if arguments[:body] && query_builder
      arguments[:body] ||= Jbuilder.encode(&query_builder)
      self.client.public_send(action, arguments)
    end
  end
end