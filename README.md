# CouchrestModelElastic [![Build Status](https://travis-ci.org/MaxiMobility/couchrest_model_elastic.png)](https://travis-ci.org/MaxiMobility/couchrest_model_elastic)

An Elasticsearch helper library, specifically for use with the `couchrest_model` gem.
Automatically sets up Elasticsearch river to watch and import from Couchdb. Adds query functionality to any class.

## Installation

Add this line to your application's Gemfile:

    gem 'couchrest_model_elastic'

Or install it yourself as:

    $ gem install couchrest_model_elastic

### Elasticsearch

[Elasticsearch](http://www.elasticsearch.org/) must be installed with the [elasticsearch-river-couchdb](https://github.com/elasticsearch/elasticsearch-river-couchdb) plugin.
To use a javascript filter on the river, the [elasticsearch-lang-javascript](https://github.com/elasticsearch/elasticsearch-lang-javascript) plugin should be installed.
Optionally, the [elasticsearch-head](https://github.com/mobz/elasticsearch-head) plugin can be used as a web frontend to Elasticsearch.

See the [install.sh](install/elasticsearch_debian_install.sh) for an automated Debian install script.

## Usage

**Basic** usage with a `CouchRest::Model::Base` class

```ruby
class User < CouchRest::Model::Base
  design do
    searchable
  end
end
```

This does the following:

 * Configures Elasticsearch create an index with the name of `User`'s database & type *User*
 * Imports all `User` documents into Elasticsearch
 * Configures Elasticsearch to watch couchdb for any changes on `User` documents and synchronize with them
 * Adds `User#named_searches` method, allowing arbitrary searches scoped to the `User` type, eg
   `User.named_searches.search { |q| q.query { q.term { q.set!(:email, 'test@test.com') } } }`

**Advanced** usage with a `CouchRest::Model::Base` class and a `Module`

```ruby
class User < CouchRest::Model::Base
  design do
    searchable do |config|
      config.set_filter(:custom_filter, "return doc['#{self.model.model_type_key}'] == '#{self.model.to_s} && doc['role'] == 'admin'")
      config.river_config.last_seq = 100
      config.named_search(:search_by_email) do |q, email, limit = 5|
        q.size limit if limit
        q.filter { q.term { q.set!(:email, email) } }
      end
    end
  end
end

module Search
  extend CouchrestModelElastic
  searchable do |config|
    config.result_source_mapper = CouchrestModelElastic::CouchModelSearchable::RESULT_MAPPER
    config.index = User.database.name
    config.river_config.script = 'if(!ctx.deleted){ for(var prop in ctx.doc) { if(/_at$/.test(prop) && ctx.doc[prop] === ""){ ctx.doc[prop] = null; }}}'
    
    config.named_search(:autocomplete) do |query, search_string, size = 10|
      query.size size
      # ... Complex query ...
    end
  end
end
```

This additionally does the following:

 * Configures Elasticsearch river to use a special filter, in this case only importing documents with type == 'User' and role == 'admin'
 * Imports starting at couchdb sequence 100
 * Creates a named_search `search_by_email`. Example usage:
   `User.search_by_email('bill@example.com')`
 * Adds search methods to the `Search` module. The results are not scoped to a *type*. Usage:
   `Search.autocomplete('hello')`
 * Applies a script so that Elasticsearch will convert all User document properties ending in _at to null if they are an empty string
 * Search results are converted into their respective `CouchRest::Model::Base` instances

   ```ruby
   > User === User.search_by_email.first.source
   => true
   ```
   
**Configuration** an example configuration in a Rails initializer

```ruby
CouchrestModelElastic.config do |config|
  config_yml = YAML.load_file(Rails.root.to_s + '/config/elasticsearch.yml')[Rails.env]
  config.hosts = config_yml['host']
  config.log = config_yml['log']
  config.trace = config_yml['trace']
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
