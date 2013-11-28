require 'elasticsearch'
require 'jbuilder'

module CouchrestModelElastic
  class Client
    attr_reader :client

    def initialize(opts = {})
      @client = Elasticsearch::Client.new(Config.to_h.merge(opts))
    end

    def search(index, args = {}, &query_builder)
      search_args = {index: index}.merge(args)
      result_mapper = search_args.delete(:result_mapper)
      SearchResults.new(perform(:search, search_args, &query_builder), &result_mapper)
    end

    def index(index, type, id, args = {}, &query_builder)
      index_args = {index: index, type: type, id: id}.merge(args)
      perform(:index, index_args, &query_builder)
    end

    def create(index, type, id, args = {}, &query_builder)
      create_args = {index: index, type: type, id: id}.merge(args)
      perform(:create, create_args, &query_builder)
    end

    protected

    def perform(action, arguments = {}, &query_builder)
      raise ArgumentError, ':body cannot be set if passed a builder block' if arguments[:body] && query_builder
      arguments[:body] ||= Jbuilder.encode(&query_builder)
      self.client.public_send(action, arguments)
    end
  end
end