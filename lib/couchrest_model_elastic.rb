require 'couchrest_model_elastic/version'
require 'ostruct'

module CouchrestModelElastic
  Config = OpenStruct.new(:hosts => [{:host => 'localhost', :port => 9200}], :log => false, :trace => false)

  def self.config(&config)
    Config.tap(&config)
  end

  def searchable(&named_searches_config)
    NamedSearches.new(&named_searches_config).tap do |named_searches|
      NamedSearches.extend_with_named_searches(self, named_searches)
    end
  end
end

require 'couchrest_model_elastic/client'
require 'couchrest_model_elastic/river'
require 'couchrest_model_elastic/search_results'
require 'couchrest_model_elastic/named_searches'
require 'couchrest_model_elastic/couch_model_searchable'