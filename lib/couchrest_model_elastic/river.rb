module CouchrestModelElastic
  class River
    RIVER_INDEX = '_river'
    META_ID = '_meta'
    META_BODY_TYPE = 'couchdb'
    STATUS_ID = '_status'
    SEQ_ID = '_seq'

    #CouchDBConfig = Struct.new(:host, :port, :db, :filter, :script)
    attr_accessor :config_index_type, :couch_db, :couch_host, :couch_port, :couch_user, :couch_password, :script, :couch_filter, :couch_filter_params, :index, :type, :last_seq, :status

    def self.new_with_defaults(config_index_type, opts = {})
      self.new.tap do |river|
        river.config_index_type = config_index_type

        river.couch_host = opts[:couch_host] || 'localhost'
        river.couch_port = opts[:couch_port] || 5984
        river.couch_db = opts[:couch_db]
        river.couch_user = opts[:couch_user]
        river.couch_password = opts[:couch_password]
        river.couch_filter = opts[:couch_filter]
        river.couch_filter_params = opts[:couch_filter_params]
        river.script = opts[:script] #|| 'ctx._type = ctx.doc.type || "null"'
        river.last_seq = opts[:last_seq]
        river.index = opts[:index]
        river.type = opts[:type]
      end
    end

    def self.fetch(config_index_type)
      self.new.tap do |river|
        river.config_index_type = config_index_type
        river.client.search(RIVER_INDEX, config_index_type).each do |result|
          doc = result.source
          case result.id
            when META_ID
              river.couch_db = doc['couchdb']['db']
              river.couch_host = doc['couchdb']['host']
              river.couch_port = doc['couchdb']['port']
              river.couch_user = doc['couchdb']['user']
              river.couch_password = doc['couchdb']['password']
              river.script = doc['couchdb']['script'] if doc['couchdb']['script']
              river.couch_filter = doc['couchdb']['filter'] if doc['couchdb']['filter']
              river.couch_filter_params = doc['couchdb']['filter_params'] if doc['couchdb']['filter_params']
            when SEQ_ID
              river.last_seq = doc['couchdb']['last_seq']
            when STATUS_ID
              river.status = doc
          end
        end
      end
    end

    def client
      @client ||= Client.new
    end

    def update
      # Configure the CouchDB river plugin to watch changes stream of given database
      self.client.index(RIVER_INDEX, self.config_index_type, META_ID) do |query|
        query.type META_BODY_TYPE
        query.couchdb do
          query.host self.couch_host
          query.port self.couch_port
          query.protocol 'https' if self.couch_port.to_i == 443
          query.db self.couch_db if self.couch_db
          query.user self.couch_user if self.couch_user
          query.password self.couch_password if self.couch_password
          query.script self.script if self.script
          query.filter self.couch_filter if self.couch_filter # River will subscribe to changes feed with given couchdb filter applied
          if self.couch_filter_params
            query.filter_params do
              self.couch_filter_params.each { |param, value| query.set! param, value }
            end
          end
        end
        query.index do
          query.index self.index if self.index
          query.type self.type if self.type
        end
      end

      # Set last_seq
      if self.last_seq
        begin
          self.client.create(RIVER_INDEX, self.config_index_type, SEQ_ID) do |query|
            query.couchdb do
              # cast to string, otherwise index will be created with type other than 'string' which can cause problems with some Couchdb versions
              query.last_seq self.last_seq.to_s
            end
          end
        rescue Elasticsearch::Transport::Transport::Errors::Conflict
          # Last seq already exists
          # no-op
        end
      end
    end
  end
end